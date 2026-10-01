const express = require("express");
const { PrismaClient } = require("@prisma/client");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const crypto = require("crypto");
const nodemailer = require("nodemailer");
require("dotenv").config();
const cors = require("cors");
const app = express();
app.use(cors());
const prisma = new PrismaClient();
const PORT = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET || "changez-cette-cle-en-production";

// Jetons de réinitialisation de mot de passe (en mémoire : token -> { email, expiresAt })
const resetTokens = new Map();

const mailTransporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST,
  port: Number(process.env.SMTP_PORT) || 587,
  secure: Number(process.env.SMTP_PORT) === 465,
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS,
  },
});

app.use(express.json({ limit: "10mb" }));

// ===================================================================
// MIDDLEWARE D'AUTHENTIFICATION
// ===================================================================
function authMiddleware(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return res.status(401).json({ error: "Token manquant" });
  }
  const token = authHeader.split(" ")[1];
  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    req.user = decoded;
    next();
  } catch (err) {
    return res.status(401).json({ error: "Token invalide ou expiré" });
  }
}

// Rôles ayant les droits de gestion complets : creer/modifier ET supprimer /
// restaurer / gerer la Corbeille. Seul AGENT_LOGISTIQUE (« Agent ») reste un
// simple observateur, en lecture seule sur tout.
const ROLES_GESTION = ["ADMIN", "DIRECTEUR_GENERAL", "RESPONSABLE_LOGISTIQUE"];

// Rôles qui n'ont pas le droit de créer/modifier les produits, catégories,
// fournisseurs et mouvements (lecture seule sur ces ressources).
const ROLES_LECTURE_SEULE = ["AGENT_LOGISTIQUE"];

function canManage(req, res, next) {
  if (!ROLES_GESTION.includes(req.user.role)) {
    return res.status(403).json({ error: "Votre rôle ne permet pas de supprimer ou de gérer la Corbeille." });
  }
  next();
}

function canWrite(req, res, next) {
  if (ROLES_LECTURE_SEULE.includes(req.user.role)) {
    return res.status(403).json({ error: "Votre rôle ne permet pas de créer ou modifier cet élément." });
  }
  next();
}

// Détecte une violation de contrainte de clé étrangère (suppression définitive
// bloquée car un autre élément y fait encore référence). Prisma remonte parfois
// ce cas sous forme d'erreur connue (code "P2003"), mais parfois aussi sous
// forme d'erreur brute du moteur de requête (violation RESTRICT côté
// PostgreSQL) qui n'a pas de "code" — d'où la vérification du message en repli.
function isForeignKeyError(err) {
  if (err && err.code === "P2003") return true;
  const msg = String((err && err.message) || "");
  return /foreign key constraint|violates .*constraint|restrict/i.test(msg);
}

// ===================================================================
// AUTHENTIFICATION
// ===================================================================
app.post("/api/auth/register", async (req, res) => {
  try {
    const { name, email, password, phone, address, avatarUrl } = req.body;
    if (!name || !email || !password) {
      return res.status(400).json({ error: "Nom, email et mot de passe requis" });
    }
    const existing = await prisma.user.findUnique({ where: { email } });
    if (existing) {
      return res.status(409).json({ error: "Cet email est déjà utilisé" });
    }
    const hashedPassword = await bcrypt.hash(password, 10);
    const user = await prisma.user.create({
      data: { name, email, password: hashedPassword, role: "EMPLOYE", phone, address, avatarUrl },
    });
    res.status(201).json({ id: user.id, name: user.name, email: user.email, role: user.role, phone: user.phone, address: user.address, avatarUrl: user.avatarUrl });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post("/api/auth/login", async (req, res) => {
  try {
    const { email, password } = req.body;
    const user = await prisma.user.findUnique({ where: { email } });
    if (!user) return res.status(401).json({ error: "Identifiants invalides" });

    const valid = await bcrypt.compare(password, user.password);
    if (!valid) return res.status(401).json({ error: "Identifiants invalides" });

    const token = jwt.sign(
      { id: user.id, email: user.email, role: user.role },
      JWT_SECRET,
      { expiresIn: "8h" }
    );
    res.json({ token, user: { id: user.id, name: user.name, email: user.email, role: user.role, phone: user.phone, address: user.address, avatarUrl: user.avatarUrl } });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});
app.get("/api/auth/me", authMiddleware, async (req, res) => {
  try {
    const user = await prisma.user.findUnique({ where: { id: req.user.id } });
    if (!user) return res.status(404).json({ error: "Utilisateur introuvable" });
    res.json({
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
      phone: user.phone,
      address: user.address,
      avatarUrl: user.avatarUrl,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.put("/api/auth/profile", authMiddleware, async (req, res) => {
  try {
    const { name, phone, address, avatarUrl } = req.body;
    const user = await prisma.user.update({
      where: { id: req.user.id },
      data: { name, phone, address, avatarUrl },
    });
    res.json({
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
      phone: user.phone,
      address: user.address,
      avatarUrl: user.avatarUrl,
    });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

app.post("/api/auth/forgot-password", async (req, res) => {
  try {
    const { email } = req.body;
    if (!email) return res.status(400).json({ error: "Email requis" });

    const user = await prisma.user.findUnique({ where: { email } });
    if (user) {
      const token = crypto.randomBytes(32).toString("hex");
      resetTokens.set(token, { email: user.email, expiresAt: Date.now() + 60 * 60 * 1000 });

      const resetUrl = `${process.env.FRONTEND_URL || "http://localhost:4200"}/reset-password?token=${token}`;
      try {
        await mailTransporter.sendMail({
          from: process.env.SMTP_FROM || process.env.SMTP_USER,
          to: user.email,
          subject: "Réinitialisation de votre mot de passe AlbideyNet",
          html: `<p>Bonjour ${user.name},</p><p>Vous avez demandé la réinitialisation de votre mot de passe AlbideyNet.</p><p>Cliquez sur le lien ci-dessous pour choisir un nouveau mot de passe (valable 1 heure) :</p><p><a href="${resetUrl}">${resetUrl}</a></p><p>Si vous n'êtes pas à l'origine de cette demande, ignorez simplement cet email.</p>`,
        });
      } catch (mailErr) {
        console.error("Erreur d'envoi d'email de réinitialisation :", mailErr.message);
      }
    }

    // Réponse identique dans tous les cas, pour ne pas révéler si l'email existe
    res.json({ message: "Si un compte existe avec cet email, un lien de réinitialisation a été envoyé." });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post("/api/auth/reset-password", async (req, res) => {
  try {
    const { token, newPassword } = req.body;
    if (!token || !newPassword) {
      return res.status(400).json({ error: "Token et nouveau mot de passe requis" });
    }

    const entry = resetTokens.get(token);
    if (!entry || entry.expiresAt < Date.now()) {
      resetTokens.delete(token);
      return res.status(400).json({ error: "Lien invalide ou expiré. Merci de refaire une demande." });
    }

    const hashedPassword = await bcrypt.hash(newPassword, 10);
    await prisma.user.update({ where: { email: entry.email }, data: { password: hashedPassword } });
    resetTokens.delete(token);

    res.json({ message: "Mot de passe réinitialisé avec succès" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ===================================================================
// CATÉGORIES
// ===================================================================
app.get("/api/categories", authMiddleware, async (req, res) => {
  const categories = await prisma.category.findMany({
    where: { deletedAt: null },
    include: { products: { where: { deletedAt: null } } },
  });
  res.json(categories);
});

app.post("/api/categories", authMiddleware, canWrite, async (req, res) => {
  try {
    const category = await prisma.category.create({ data: { name: req.body.name } });
    res.status(201).json(category);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

app.put("/api/categories/:id", authMiddleware, canWrite, async (req, res) => {
  try {
    const category = await prisma.category.update({
      where: { id: Number(req.params.id) },
      data: { name: req.body.name },
    });
    res.json(category);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

app.delete("/api/categories/:id", authMiddleware, canManage, async (req, res) => {
  try {
    await prisma.category.update({
      where: { id: Number(req.params.id) },
      data: { deletedAt: new Date() },
    });
    res.status(204).send();
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

app.post("/api/categories/:id/restore", authMiddleware, canManage, async (req, res) => {
  try {
    const category = await prisma.category.update({
      where: { id: Number(req.params.id) },
      data: { deletedAt: null },
    });
    res.json(category);
  } catch (err) {
    if (err.code === "P2002") {
      return res.status(400).json({ error: "Impossible de restaurer : le nom existe déjà sur une catégorie active." });
    }
    res.status(400).json({ error: err.message });
  }
});

app.delete("/api/categories/:id/permanent", authMiddleware, canManage, async (req, res) => {
  try {
    await prisma.category.delete({ where: { id: Number(req.params.id) } });
    res.status(204).send();
  } catch (err) {
    if (isForeignKeyError(err)) {
      return res.status(400).json({ error: "Impossible de supprimer définitivement : cette catégorie est encore liée à des produits." });
    }
    res.status(400).json({ error: err.message });
  }
});

// ===================================================================
// FOURNISSEURS
// ===================================================================
app.get("/api/suppliers", authMiddleware, async (req, res) => {
  const suppliers = await prisma.supplier.findMany({
    where: { deletedAt: null },
    include: { products: { where: { deletedAt: null } } },
  });
  res.json(suppliers);
});

app.post("/api/suppliers", authMiddleware, canWrite, async (req, res) => {
  try {
    const supplier = await prisma.supplier.create({ data: req.body });
    res.status(201).json(supplier);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

app.put("/api/suppliers/:id", authMiddleware, canWrite, async (req, res) => {
  try {
    const supplier = await prisma.supplier.update({
      where: { id: Number(req.params.id) },
      data: req.body,
    });
    res.json(supplier);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

app.delete("/api/suppliers/:id", authMiddleware, canManage, async (req, res) => {
  try {
    await prisma.supplier.update({
      where: { id: Number(req.params.id) },
      data: { deletedAt: new Date() },
    });
    res.status(204).send();
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

app.post("/api/suppliers/:id/restore", authMiddleware, canManage, async (req, res) => {
  try {
    const supplier = await prisma.supplier.update({
      where: { id: Number(req.params.id) },
      data: { deletedAt: null },
    });
    res.json(supplier);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

app.delete("/api/suppliers/:id/permanent", authMiddleware, canManage, async (req, res) => {
  try {
    await prisma.supplier.delete({ where: { id: Number(req.params.id) } });
    res.status(204).send();
  } catch (err) {
    if (isForeignKeyError(err)) {
      return res.status(400).json({ error: "Impossible de supprimer définitivement : ce fournisseur est encore lié à des produits." });
    }
    res.status(400).json({ error: err.message });
  }
});

// ===================================================================
// PRODUITS
// ===================================================================
app.get("/api/products", authMiddleware, async (req, res) => {
  const products = await prisma.product.findMany({
    where: { deletedAt: null },
    include: { category: true, supplier: true },
    orderBy: { name: "asc" },
  });
  res.json(products);
});

app.get("/api/products/low-stock", authMiddleware, async (req, res) => {
  const products = await prisma.product.findMany({
    where: { deletedAt: null },
    include: { category: true, supplier: true },
  });
  const lowStock = products.filter((p) => p.quantity <= p.minQuantity);
  res.json(lowStock);
});

app.get("/api/products/:id", authMiddleware, async (req, res) => {
  const product = await prisma.product.findFirst({
    where: { id: Number(req.params.id), deletedAt: null },
    include: { category: true, supplier: true, movements: true },
  });
  if (!product) return res.status(404).json({ error: "Produit introuvable" });
  res.json(product);
});

app.post("/api/products", authMiddleware, canWrite, async (req, res) => {
  try {
    const { name, sku, description, price, quantity, minQuantity, categoryId, supplierId, imageUrl } = req.body;
    const product = await prisma.product.create({
      data: {
        name,
        sku,
        description,
        imageUrl,
        price: Number(price),
        quantity: Number(quantity) || 0,
        minQuantity: Number(minQuantity) || 5,
        categoryId: categoryId ? Number(categoryId) : null,
        supplierId: supplierId ? Number(supplierId) : null,
      },
    });
    res.status(201).json(product);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

app.put("/api/products/:id", authMiddleware, canWrite, async (req, res) => {
  try {
    const product = await prisma.product.update({
      where: { id: Number(req.params.id) },
      data: req.body,
    });
    res.json(product);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

app.delete("/api/products/:id", authMiddleware, canManage, async (req, res) => {
  try {
    await prisma.product.update({
      where: { id: Number(req.params.id) },
      data: { deletedAt: new Date() },
    });
    res.status(204).send();
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

app.post("/api/products/:id/restore", authMiddleware, canManage, async (req, res) => {
  try {
    const product = await prisma.product.update({
      where: { id: Number(req.params.id) },
      data: { deletedAt: null },
    });
    res.json(product);
  } catch (err) {
    if (err.code === "P2002") {
      return res.status(400).json({ error: "Impossible de restaurer : le SKU existe déjà sur un produit actif." });
    }
    res.status(400).json({ error: err.message });
  }
});

app.delete("/api/products/:id/permanent", authMiddleware, canManage, async (req, res) => {
  try {
    await prisma.product.delete({ where: { id: Number(req.params.id) } });
    res.status(204).send();
  } catch (err) {
    if (isForeignKeyError(err)) {
      return res.status(400).json({ error: "Impossible de supprimer définitivement : ce produit a des mouvements de stock liés." });
    }
    res.status(400).json({ error: err.message });
  }
});

// ===================================================================
// MOUVEMENTS DE STOCK (ENTRÉES / SORTIES)
// ===================================================================
app.get("/api/movements", authMiddleware, async (req, res) => {
  const movements = await prisma.stockMovement.findMany({
    where: { deletedAt: null },
    include: { product: true, user: true },
    orderBy: { createdAt: "desc" },
  });
  res.json(movements);
});

app.post("/api/movements", authMiddleware, canWrite, async (req, res) => {
  const { productId, type, quantity, reason, date } = req.body;

  if (!["ENTREE", "SORTIE"].includes(type)) {
    return res.status(400).json({ error: "Type doit être ENTREE ou SORTIE" });
  }

  try {
    const result = await prisma.$transaction(async (tx) => {
      const product = await tx.product.findUnique({ where: { id: Number(productId) } });
      if (!product) throw new Error("Produit introuvable");

      const newQuantity =
        type === "ENTREE" ? product.quantity + Number(quantity) : product.quantity - Number(quantity);

      if (newQuantity < 0) throw new Error("Stock insuffisant pour cette sortie");

      await tx.product.update({
        where: { id: product.id },
        data: { quantity: newQuantity },
      });

      return tx.stockMovement.create({
        data: {
          productId: product.id,
          type,
          quantity: Number(quantity),
          reason,
          userId: req.user.id,
          ...(date ? { createdAt: new Date(date) } : {}),
        },
      });
    });

    res.status(201).json(result);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

app.put("/api/movements/:id", authMiddleware, canWrite, async (req, res) => {
  const { productId, type, quantity, reason, date } = req.body;

  if (!["ENTREE", "SORTIE"].includes(type)) {
    return res.status(400).json({ error: "Type doit être ENTREE ou SORTIE" });
  }

  try {
    const result = await prisma.$transaction(async (tx) => {
      const movement = await tx.stockMovement.findUnique({ where: { id: Number(req.params.id) } });
      if (!movement) throw new Error("Mouvement introuvable");

      const oldProduct = await tx.product.findUnique({ where: { id: movement.productId } });
      if (!oldProduct) throw new Error("Produit d'origine introuvable");

      const revertedQuantity =
        movement.type === "ENTREE"
          ? oldProduct.quantity - movement.quantity
          : oldProduct.quantity + movement.quantity;

      if (revertedQuantity < 0) {
        throw new Error("Impossible de modifier ce mouvement : le stock deviendrait négatif après annulation");
      }

      await tx.product.update({
        where: { id: oldProduct.id },
        data: { quantity: revertedQuantity },
      });

      const newProduct = await tx.product.findUnique({ where: { id: Number(productId) } });
      if (!newProduct) throw new Error("Produit introuvable");

      const baseQuantity = newProduct.id === oldProduct.id ? revertedQuantity : newProduct.quantity;

      const finalQuantity =
        type === "ENTREE" ? baseQuantity + Number(quantity) : baseQuantity - Number(quantity);

      if (finalQuantity < 0) {
        throw new Error("Stock insuffisant pour cette sortie");
      }

      await tx.product.update({
        where: { id: newProduct.id },
        data: { quantity: finalQuantity },
      });

      return tx.stockMovement.update({
        where: { id: movement.id },
        data: {
          productId: Number(productId),
          type,
          quantity: Number(quantity),
          reason,
          ...(date ? { createdAt: new Date(date) } : {}),
        },
      });
    });

    res.json(result);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

app.delete("/api/movements/:id", authMiddleware, canManage, async (req, res) => {
  try {
    await prisma.$transaction(async (tx) => {
      const movement = await tx.stockMovement.findFirst({ where: { id: Number(req.params.id), deletedAt: null } });
      if (!movement) throw new Error("Mouvement introuvable");

      const product = await tx.product.findUnique({ where: { id: movement.productId } });
      if (!product) throw new Error("Produit introuvable");

      const revertedQuantity =
        movement.type === "ENTREE"
          ? product.quantity - movement.quantity
          : product.quantity + movement.quantity;

      if (revertedQuantity < 0) {
        throw new Error("Impossible de supprimer ce mouvement : le stock deviendrait négatif");
      }

      await tx.product.update({
        where: { id: product.id },
        data: { quantity: revertedQuantity },
      });

      await tx.stockMovement.update({
        where: { id: movement.id },
        data: { deletedAt: new Date() },
      });
    });

    res.status(204).send();
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

app.post("/api/movements/:id/restore", authMiddleware, canManage, async (req, res) => {
  try {
    const result = await prisma.$transaction(async (tx) => {
      const movement = await tx.stockMovement.findUnique({ where: { id: Number(req.params.id) } });
      if (!movement || !movement.deletedAt) throw new Error("Mouvement introuvable dans la corbeille");

      const product = await tx.product.findUnique({ where: { id: movement.productId } });
      if (!product) throw new Error("Produit introuvable");

      const newQuantity =
        movement.type === "ENTREE"
          ? product.quantity + movement.quantity
          : product.quantity - movement.quantity;

      if (newQuantity < 0) {
        throw new Error("Impossible de restaurer ce mouvement : le stock du produit deviendrait négatif");
      }

      await tx.product.update({
        where: { id: product.id },
        data: { quantity: newQuantity },
      });

      return tx.stockMovement.update({
        where: { id: movement.id },
        data: { deletedAt: null },
      });
    });

    res.json(result);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

app.delete("/api/movements/:id/permanent", authMiddleware, canManage, async (req, res) => {
  try {
    await prisma.stockMovement.delete({ where: { id: Number(req.params.id) } });
    res.status(204).send();
  } catch (err) {
    if (isForeignKeyError(err)) {
      return res.status(400).json({ error: "Impossible de supprimer définitivement : ce mouvement est encore lié à un autre élément." });
    }
    res.status(400).json({ error: err.message });
  }
});

// ===================================================================
// CORBEILLE (ÉLÉMENTS SUPPRIMÉS)
// ===================================================================
app.get("/api/trash", authMiddleware, canManage, async (req, res) => {
  try {
    const [products, categories, suppliers, movements] = await Promise.all([
      prisma.product.findMany({
        where: { deletedAt: { not: null } },
        include: { category: true, supplier: true },
        orderBy: { deletedAt: "desc" },
      }),
      prisma.category.findMany({
        where: { deletedAt: { not: null } },
        orderBy: { deletedAt: "desc" },
      }),
      prisma.supplier.findMany({
        where: { deletedAt: { not: null } },
        orderBy: { deletedAt: "desc" },
      }),
      prisma.stockMovement.findMany({
        where: { deletedAt: { not: null } },
        include: { product: true },
        orderBy: { deletedAt: "desc" },
      }),
    ]);

    res.json({ products, categories, suppliers, movements });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ===================================================================
// DÉMARRAGE DU SERVEUR
// ===================================================================
app.listen(PORT, () => {
  console.log(`Serveur AlbideyNet démarré sur http://localhost:${PORT}`);
});


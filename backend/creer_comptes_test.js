// Cree (ou met a jour) 3 comptes de test, un par nouveau role, pour pouvoir
// se connecter directement dans l'application et voir le badge de role.
const { PrismaClient } = require("@prisma/client");
const bcrypt = require("bcryptjs");

const prisma = new PrismaClient();

async function main() {
  const password = "Test1234!";
  const hashedPassword = await bcrypt.hash(password, 10);

  const users = [
    { name: "Agent Logistique Test", email: "agent.logistique@albideynet.com", role: "AGENT_LOGISTIQUE" },
    { name: "Responsable Logistique Test", email: "responsable.logistique@albideynet.com", role: "RESPONSABLE_LOGISTIQUE" },
    { name: "Directeur General Test", email: "directeur.general@albideynet.com", role: "DIRECTEUR_GENERAL" },
  ];

  for (const u of users) {
    const result = await prisma.user.upsert({
      where: { email: u.email },
      update: { role: u.role, password: hashedPassword, name: u.name },
      create: { name: u.name, email: u.email, password: hashedPassword, role: u.role },
    });
    console.log("OK : " + result.email + " -> role " + result.role);
  }

  console.log("");
  console.log("Mot de passe pour ces 3 comptes : " + password);
}

main()
  .catch((err) => {
    console.error("ERREUR :", err.message);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

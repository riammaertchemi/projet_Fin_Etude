const bcrypt = require('bcryptjs');
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function resetPassword() {
  const newPassword = 'admin123';
  const hashed = await bcrypt.hash(newPassword, 10);

  await prisma.user.update({
    where: { email: 'admin@albideynet.com' },
    data: { password: hashed }
  });

  console.log('Mot de passe réinitialisé avec succès. Nouveau mot de passe :', newPassword);
  await prisma.$disconnect();
}

resetPassword();
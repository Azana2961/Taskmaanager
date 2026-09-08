const prisma = require('../../config/db');

exports.getAll = async (req, res, next) => {
  try {
    const tags = await prisma.tag.findMany({
      where: {
        OR: [
          {
            project: {
              members: { some: { id: req.user.userId } } // NOTE: in other controllers, it's req.user.userId
            }
          },
          { projectId: null } // allow global tags if any exist
        ]
      },
      orderBy: { createdAt: 'asc' },
    });
    res.json(tags);
  } catch (error) {
    next(error);
  }
};

exports.create = async (req, res, next) => {
  try {
    const { name, color, projectId } = req.body;
    const tag = await prisma.tag.create({
      data: { name, color, projectId },
    });
    res.status(201).json(tag);
  } catch (error) {
    next(error);
  }
};

exports.update = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { name, color } = req.body;
    const tag = await prisma.tag.update({
      where: { id },
      data: { name, color },
    });
    res.json(tag);
  } catch (error) {
    next(error);
  }
};

exports.remove = async (req, res, next) => {
  try {
    const { id } = req.params;
    await prisma.tag.delete({
      where: { id },
    });
    res.status(204).send();
  } catch (error) {
    next(error);
  }
};

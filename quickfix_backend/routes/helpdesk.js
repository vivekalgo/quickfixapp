const express = require('express');
const router = express.Router();
const helpdeskController = require('../controllers/helpdeskController');
const { requireAuth, requireAdmin, optionalAuth } = require('../middleware/auth');
const { publicLimiter } = require('../middleware/rateLimiter');

// --- PUBLIC & CUSTOMER / PROVIDER HELPDESK ROUTES ---
router.post('/chat', publicLimiter, optionalAuth, helpdeskController.postChatMessage);
router.get('/tickets/user', requireAuth, helpdeskController.getUserTickets);
router.get('/tickets/detail/:ticketId', optionalAuth, helpdeskController.getTicketById);
router.get('/kb', optionalAuth, helpdeskController.getKbArticles);

// --- ADMIN HELPDESK & AI MANAGEMENT ROUTES ---
router.get('/tickets/admin', requireAdmin, helpdeskController.getAdminTickets);
router.post('/tickets/admin/reply/:ticketId', requireAdmin, helpdeskController.addAdminReply);
router.patch('/tickets/admin/status/:ticketId', requireAdmin, helpdeskController.updateTicketStatus);
router.post('/tickets/admin/refund/:ticketId', requireAdmin, helpdeskController.processRefundAction);
router.get('/tickets/admin/ai-tools/:ticketId', requireAdmin, helpdeskController.getAdminAiSuggestions);

router.post('/kb', requireAdmin, helpdeskController.createKbArticle);
router.put('/kb/:id', requireAdmin, helpdeskController.updateKbArticle);
router.delete('/kb/:id', requireAdmin, helpdeskController.deleteKbArticle);

router.get('/analytics', requireAdmin, helpdeskController.getAnalytics);

module.exports = router;

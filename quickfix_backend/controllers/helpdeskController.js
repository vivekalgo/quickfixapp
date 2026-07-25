const helpdeskService = require('../services/helpdeskService');

// 1. Customer / Provider Chat Message Endpoint
async function postChatMessage(req, res) {
  try {
    const { message, ticketId, attachments, platform, appVersion, deviceInfo } = req.body;
    if (!message || message.trim().length === 0) {
      return res.status(400).json({ success: false, error: 'Message content is required' });
    }

    const payload = {
      customerId: req.user ? (req.user.id || req.user.userId || req.user.phone) : (req.body.customerId || 'guest'),
      customerName: req.user ? (req.user.name || req.user.username) : (req.body.customerName || 'Customer'),
      customerPhone: req.user ? (req.user.phone || '') : (req.body.customerPhone || ''),
      customerEmail: req.user ? (req.user.email || '') : (req.body.customerEmail || ''),
      userText: message,
      ticketId,
      attachments,
      platform: platform || 'mobile',
      appVersion: appVersion || '1.0.0',
      deviceInfo: deviceInfo || {}
    };

    const result = await helpdeskService.processCustomerMessage(payload);
    res.json({ success: true, data: result });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message || 'Failed to process message' });
  }
}

// 2. Fetch User Tickets
async function getUserTickets(req, res) {
  try {
    const customerId = req.user ? (req.user.id || req.user.userId || req.user.phone) : req.query.customerId;
    if (!customerId) {
      return res.status(400).json({ success: false, error: 'Customer identification required' });
    }
    const tickets = await helpdeskService.getAdminTickets({ search: String(customerId) });
    res.json({ success: true, tickets });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message || 'Failed to fetch user tickets' });
  }
}

// 3. Get Single Ticket Details
async function getTicketById(req, res) {
  try {
    const { ticketId } = req.params;
    const tickets = await helpdeskService.getAdminTickets({ search: ticketId });
    if (!tickets || tickets.length === 0) {
      return res.status(404).json({ success: false, error: 'Ticket not found' });
    }
    res.json({ success: true, ticket: tickets[0] });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message || 'Failed to fetch ticket' });
  }
}

// 4. Admin Get All Tickets
async function getAdminTickets(req, res) {
  try {
    const filters = {
      status: req.query.status,
      category: req.query.category,
      priority: req.query.priority,
      search: req.query.search
    };
    const tickets = await helpdeskService.getAdminTickets(filters);
    res.json({ success: true, tickets });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message || 'Failed to fetch admin tickets' });
  }
}

// 5. Admin Add Reply
async function addAdminReply(req, res) {
  try {
    const { ticketId } = req.params;
    const { text, attachments } = req.body;
    if (!text || text.trim().length === 0) {
      return res.status(400).json({ success: false, error: 'Reply text is required' });
    }
    const adminName = req.user ? (req.user.username || req.user.name || 'Admin') : 'Support Admin';
    const updatedTicket = await helpdeskService.addAdminReply(ticketId, adminName, text, attachments);
    res.json({ success: true, ticket: updatedTicket });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message || 'Failed to post admin reply' });
  }
}

// 6. Admin Update Ticket Status / Priority / Assignee
async function updateTicketStatus(req, res) {
  try {
    const { ticketId } = req.params;
    const { status, assignedAdmin, priority } = req.body;
    const updatedTicket = await helpdeskService.updateTicketStatus(ticketId, status, assignedAdmin, priority);
    res.json({ success: true, ticket: updatedTicket });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message || 'Failed to update ticket' });
  }
}

// 7. Admin Process Refund
async function processRefundAction(req, res) {
  try {
    const { ticketId } = req.params;
    const { action, refundNote } = req.body; // 'approve' or 'reject'
    if (!action || !['approve', 'reject'].includes(action)) {
      return res.status(400).json({ success: false, error: "Action must be 'approve' or 'reject'" });
    }
    const adminName = req.user ? (req.user.username || req.user.name || 'Admin') : 'Support Admin';
    const updatedTicket = await helpdeskService.processRefundAction(ticketId, action, adminName, refundNote);
    res.json({ success: true, ticket: updatedTicket });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message || 'Failed to process refund' });
  }
}

// 8. Admin AI Helper Suggestions
async function getAdminAiSuggestions(req, res) {
  try {
    const { ticketId } = req.params;
    const suggestions = await helpdeskService.getAdminAiTools(ticketId);
    res.json({ success: true, data: suggestions });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message || 'Failed to generate AI suggestions' });
  }
}

// 9. Knowledge Base Manager APIs
async function getKbArticles(req, res) {
  try {
    const filters = {
      category: req.query.category,
      search: req.query.search
    };
    const articles = await helpdeskService.getKbArticles(filters);
    res.json({ success: true, articles });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message || 'Failed to fetch KB articles' });
  }
}

async function createKbArticle(req, res) {
  try {
    const article = await helpdeskService.createKbArticle(req.body);
    res.json({ success: true, article });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message || 'Failed to create KB article' });
  }
}

async function updateKbArticle(req, res) {
  try {
    const { id } = req.params;
    const article = await helpdeskService.updateKbArticle(id, req.body);
    res.json({ success: true, article });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message || 'Failed to update KB article' });
  }
}

async function deleteKbArticle(req, res) {
  try {
    const { id } = req.params;
    await helpdeskService.deleteKbArticle(id);
    res.json({ success: true, message: 'KB article deleted successfully' });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message || 'Failed to delete KB article' });
  }
}

// 10. Helpdesk Analytics
async function getAnalytics(req, res) {
  try {
    const analytics = await helpdeskService.getHelpdeskAnalytics();
    res.json({ success: true, analytics });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message || 'Failed to fetch helpdesk analytics' });
  }
}

module.exports = {
  postChatMessage,
  getUserTickets,
  getTicketById,
  getAdminTickets,
  addAdminReply,
  updateTicketStatus,
  processRefundAction,
  getAdminAiSuggestions,
  getKbArticles,
  createKbArticle,
  updateKbArticle,
  deleteKbArticle,
  getAnalytics
};

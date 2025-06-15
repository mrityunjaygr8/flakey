return {
  "folke/todo-comments.nvim",
  keys = {
    { "<leader>tt", function() Snacks.picker.todo_comments() end, desc = "Todo" },
    { "<leader>tT", function () Snacks.picker.todo_comments({ keywords = { "TODO", "FIX", "FIXME" } }) end, desc = "Todo/Fix/Fixme" },
  },
}

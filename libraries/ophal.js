/**
 * Ophal jQuery library.
 */

(function($) {window.Ophal = new function(namespace, func) {

this.set_message = function(message) {
  var message = $('<div class="error-message">' + message + '</div>');
  $(message).click(function () {
    if (confirm('Do you wish to hide this message?')) {
      $(this).remove();
    }
  });
  $('#messages').append(message);
};

this.extend = function (namespace, func) {
  (this[namespace] = func)($);
};

}})(jQuery);
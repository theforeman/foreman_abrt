$(function () {
  var button = $("#forward_auth_button")
  var dialog = $("#forward_auth")

  dialog.modal({
    backdrop: 'static',
    show: false
  })

  button.on('click', function () {
    dialog.modal('show')
  });
});

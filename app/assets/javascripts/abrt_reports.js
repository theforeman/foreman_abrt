$(function () {
  // basic http auth modal dialog setup
  var button = $("#forward_auth_button")
  var dialog = $("#forward_auth")

  dialog.modal({
    backdrop: 'static',
    show: false
  })

  button.on('click', function () {
    dialog.modal('show')
  });

  // filling the dialog with redhat_access credentials
  var token = localStorage.getItem('rhAuthToken');
  var rhUser = '';
  var rhPass = '';
  if (token) {
     try {
        decoded = atob(token);
        colonPos = decoded.indexOf(':');
        if (colonPos != -1) {
          rhUser = decoded.substring(0, colonPos);
          rhPass = decoded.substring(colonPos+1);
          $("#redhat_access_alert_login").hide();
          $("#redhat_access_alert_use").show();
        }
     } catch(err) {}
  }

  $("#redhat_access_fill").on('click', function (e) {
    e.preventDefault();
    $("#username").val(rhUser);
    $("#password").val(rhPass);
  });
});

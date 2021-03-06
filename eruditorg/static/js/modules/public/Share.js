import '!!script!jquery.validation/dist/jquery.validate.min';
import '!!script!jquery.validation/src/localization/messages_fr';
import '!!script!magnific-popup/dist/jquery.magnific-popup.min';
import SharingUtils from '../../core/SharingUtils';

class ShareModal {

  constructor(el) {

    this.el    = el;
    this.title = el.data('title') || document.title;
    this.url   = el.data('share-url') || window.location.href;
    this.citation_text = $(el.data('cite')).text();

    this.init();
  }

  init() {
    this.el.magnificPopup({
      mainClass: 'mfp-fade',
      removalDelay: 750,
      closeOnBgClick: true,
      closeBtnInside: true,
      showCloseBtn: false,
      items: {
        src: '<div class="modal share-modal col-lg-3 col-md-5 col-sm-6 col-xs-12 col-centered">\
                <div class="panel">\
                  <header class="panel-heading">\
                    <h2 class="h4 panel-title text-center">' + gettext('Partager ce document') + '</h2>\
                  </header>\
                  <div class="panel-body share-modal--body">\
                    <ul class="unstyled">\
                      <li><button id="share-email" class="btn btn-primary btn-block"><span class="ion ion-ios-email"></span>' + gettext('Courriel') + '</button></li>\
                      <li><button id="share-twitter" class="btn btn-primary btn-block"><span class="ion ion-social-twitter"></span>Twitter</button></li>\
                      <li><button id="share-facebook" class="btn btn-primary btn-block"><span class="ion ion-social-facebook"></span>Facebook</button></li>\
                      <li><button id="share-linkedin" class="btn btn-primary btn-block"><span class="ion ion-social-linkedin"></span>LinkedIn</button></li>\
                    </ul>\
                  </div>\
                </div>\
              </div>',
        type: 'inline'
      },
      callbacks: {
        open: () => {

          var $modal = $($.magnificPopup.instance.content);

          $modal.on('click', '#share-email', (event) => {
            event.preventDefault();

            SharingUtils.email( this.url, this.title, this.citation_text.replace(/(\r\n|\n|\r)/gm,""));
            return false;
          });

          $modal.on('click', '#share-twitter', (event) => {
            event.preventDefault();

            SharingUtils.twitter( this.url, this.title );
            return false;
          });

          $modal.on('click', '#share-facebook', (event) => {
            event.preventDefault();

            SharingUtils.facebook( this.url, this.title );
            return false;
          });

          $modal.on('click', '#share-linkedin', (event) => {
            event.preventDefault();

            SharingUtils.linkedin( this.url, this.title );
            return false;
          });

        },
        close: () => {
          $($.magnificPopup.instance.content).off('click');
        }
      }
    });

  }



}

export default ShareModal;

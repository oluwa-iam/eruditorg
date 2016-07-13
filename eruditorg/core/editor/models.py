# -*- coding: utf-8 -*-

from django.conf import settings
from django.contrib.auth.models import Group
from django.core.urlresolvers import reverse
from django.db import models
from django.db.models import F
from django.utils.translation import gettext as _

from django_fsm import FSMField, transition


class IssueSubmission(models.Model):
    """ A journal issue submission by an editor """

    DRAFT = "D"
    SUBMITTED = "S"
    VALID = "V"

    STATUS_CHOICES = (
        (DRAFT, _("Brouillon")),
        (SUBMITTED, _("Soumis")),
        (VALID, _("Validé")),
    )

    status = FSMField(default=DRAFT, protected=False)

    journal = models.ForeignKey(
        'erudit.journal',
        verbose_name=_("Revue"),
    )

    year = models.CharField(
        max_length=9,
        verbose_name=_("Année")
    )

    volume = models.CharField(
        max_length=100,
        verbose_name=_("Volume"),
        blank=True, null=True
    )

    number = models.CharField(
        max_length=100,
        verbose_name=_("Numéro")
    )

    date_created = models.DateTimeField(
        auto_now_add=True,
        editable=False,
        verbose_name=_("Date de l'envoi"),
    )

    date_modified = models.DateTimeField(
        auto_now=True,
        editable=False,
        verbose_name=_("Date de modification"),
    )

    contact = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        verbose_name=_("Personne contact")
    )

    comment = models.TextField(
        verbose_name=_("Commentaire"),
        blank=True, null=True
    )

    archived = models.BooleanField(
        verbose_name=_('Archivé'),
        default=False,
    )

    class Meta:
        verbose_name = _("Envoi de numéro")
        verbose_name_plural = _("Envois de numéros")

    def __str__(self):
        return "{} - {}, volume {}".format(
            self.date_created,
            self.journal,
            self.volume
        )

    def get_absolute_url(self):
        """ Return the absolute URL for this model """
        return reverse('userspace:journal:editor:update',
                       kwargs={'journal_pk': self.journal.pk, 'pk': self.pk})

    @property
    def is_draft(self):
        return self.status == self.DRAFT

    @property
    def is_submitted(self):
        return self.status == self.SUBMITTED

    @property
    def is_validated(self):
        return self.status == self.VALID

    @transition(field=status, source=DRAFT, target=SUBMITTED,
                permission=lambda user: user.has_perm(
                    'editor.manage_issuesubmission'),
                custom=dict(verbose_name=("Soumettre")))
    def submit(self):
        """
        Send issue for review
        """
        # Removes the incomplete files associated with the issue submission
        incompletes = self.last_files_version.submissions.exclude(filesize=F('uploadsize'))
        [rf.delete() for rf in incompletes]

    @transition(field=status, source=SUBMITTED, target=VALID,
                permission=lambda user: user.has_perm(
                    'editor.review_issuesubmission'),
                custom=dict(verbose_name=_("Approuver")))
    def approve(self):
        """
        Validate the issue
        """
        pass

    @transition(field=status, source=SUBMITTED, target=DRAFT,
                permission=lambda user: user.has_perm(
                    'editor.review_issuesubmission'),
                custom=dict(verbose_name=_("Marquer à corriger")))
    def refuse(self):
        """
        Resend the issue for modifications
        """
        self.save_version()

    def save(self, *args, **kwargs):
        created = self.pk is None
        super(IssueSubmission, self).save(*args, **kwargs)
        if created:
            # The IssueSubmission instance is being created ; so we force
            # the creation of an IssueSubmissionFilesVersion instance.
            self.save_version()

    def save_version(self):
        return IssueSubmissionFilesVersion.objects.create(issue_submission=self)

    @property
    def last_files_version(self):
        return self.files_versions.order_by('-created').first()

    @property
    def last_status_track(self):
        return self.status_tracks.order_by('-created').first()

    def get_status_display(self):
        status_choices_dict = dict(self.STATUS_CHOICES)
        if self.status != self.DRAFT:
            return status_choices_dict[self.status]
        elif self.status == self.DRAFT and self.last_status_track is None:
            return _('Non soumis')
        return _('À corriger')


class IssueSubmissionStatusTrack(models.Model):
    """ Tracks the changes of an issue submission status. """
    issue_submission = models.ForeignKey(
        IssueSubmission, related_name='status_tracks', verbose_name=_('Changements de statut'))
    created = models.DateTimeField(auto_now_add=True, verbose_name=_('Date de création'))
    status = models.CharField(max_length=100, verbose_name=_('statut'))
    files_version = models.ForeignKey(
        'IssueSubmissionFilesVersion', verbose_name=_('Version des fichiers'),
        blank=True, null=True)

    # A comment can be written when the status of an issue submission is updated by a user.
    # eg. when the status is changed from draft -> to submitted
    comment = models.TextField(verbose_name=_('Commentaire'), blank=True, null=True)

    class Meta:
        ordering = ['created', ]
        verbose_name = _("Changement de statut d'un envoi de numéro")
        verbose_name_plural = _("Changements de statut d'envois de numéro")


class IssueSubmissionFilesVersion(models.Model):
    """ An issue submission files version. """
    issue_submission = models.ForeignKey(
        IssueSubmission, related_name='files_versions', verbose_name=_('Envoi de numéro'))
    created = models.DateTimeField(auto_now_add=True, verbose_name=_('Date de création'))
    updated = models.DateTimeField(auto_now=True, verbose_name=_('Date de modification'))
    submissions = models.ManyToManyField('plupload.ResumableFile')

    class Meta:
        ordering = ['created', ]
        verbose_name = _("Version de fichiers d'un envoi de numéro")
        verbose_name_plural = _("Versions de fichiers d'envois de numéro")


class ProductionTeam(models.Model):
    """ Represents an Érudit production team. """
    group = models.OneToOneField(Group, verbose_name=_('Groupe'))
    identifier = models.SlugField(
        max_length=48, unique=True, verbose_name=_('Identifiant'), db_index=True)
    journals = models.ManyToManyField('erudit.Journal', verbose_name=_('Revues'))

    class Meta:
        verbose_name = _('Équipe de production')
        verbose_name_plural = _('Équipes de production')

from ...legacy.command import Command as BaseCommand  # NOQA

from erudit.models import Journal

from ...models import OrganizationPolicy, IndividualAccountJournal


class Command(BaseCommand):

    def _add_permission(self, accounts, journals):
        for account in accounts:
            for journal in journals:
                rule, created = IndividualAccountJournal.get_or_create(
                    account=account,
                    journal=journal)
                if created:
                    log = '{} {}'.format(account, journal)
                    self.stdout.write(log)

    def permissions(self):
        organisations = OrganizationPolicy.objects.all()
        for organisation in organisations:
            accounts = organisation.accounts.all()

            if organisation.access_full:
                journals = Journal.objects.all()
                self._add_permission(accounts, journals)

# -*- coding: utf-8 -*-

from django.contrib import messages
from django.contrib.auth import update_session_auth_hash
from django.contrib.auth.forms import PasswordChangeForm
from django.core.urlresolvers import reverse
from django.utils.translation import ugettext_lazy as _
from django.views.generic import UpdateView
from django.views.generic import FormView

from base.viewmixins import LoginRequiredMixin
from base.viewmixins import MenuItemMixin

from .forms import UserParametersForm
from .forms import UserPersonalDataForm


class UserPersonalDataUpdateView(LoginRequiredMixin, MenuItemMixin, UpdateView):
    form_class = UserPersonalDataForm
    menu_account = 'personal'
    template_name = 'public/auth/personal_data.html'

    def get_object(self):
        return self.request.user

    def form_valid(self, form):
        messages.success(
            self.request, _('Vos informations personelles ont été mises à jour avec succès.'))
        return super(UserPersonalDataUpdateView, self).form_valid(form)

    def get_success_url(self):
        return reverse('public:auth:personal_data')


class UserParametersUpdateView(LoginRequiredMixin, MenuItemMixin, UpdateView):
    form_class = UserParametersForm
    menu_account = 'parameters'
    template_name = 'public/auth/parameters.html'

    def get_object(self):
        return self.request.user

    def form_valid(self, form):
        messages.success(self.request, _('Votre compte a été mis à jour avec succès.'))
        return super(UserParametersUpdateView, self).form_valid(form)

    def get_success_url(self):
        return reverse('public:auth:parameters')


class UserPasswordChangeView(LoginRequiredMixin, MenuItemMixin, FormView):
    form_class = PasswordChangeForm
    menu_account = 'password'
    template_name = 'public/auth/password_change.html'

    def get_form_kwargs(self):
        kwargs = super(UserPasswordChangeView, self).get_form_kwargs()
        kwargs.update({'user': self.request.user})
        return kwargs

    def get_success_url(self):
        return reverse('public:auth:password_change')

    def form_valid(self, form):
        form.save()
        messages.success(self.request, _('Votre mot de passe a été mis à jour avec succès'))
        update_session_auth_hash(self.request, form.user)
        return super(UserPasswordChangeView, self).form_valid(form)

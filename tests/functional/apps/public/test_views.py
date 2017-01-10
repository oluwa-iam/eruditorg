# -*- coding: utf-8 -*-
import os
import pickle
import datetime as dt

import unittest
from django.core.urlresolvers import reverse
from django.test.utils import override_settings
import feedparser

from erudit.test.factories import IssueFactory
from erudit.test.factories import JournalFactory
from erudit.test import BaseEruditTestCase

FIXTURE_ROOT = os.path.join(os.path.dirname(__file__), 'fixtures')

@override_settings(DEBUG=True)
class TestHomeView(BaseEruditTestCase):
    def test_embeds_the_latest_issues_into_the_context(self):
        # Setup
        issue_1 = IssueFactory.create(
            journal=self.journal, date_published=dt.datetime.now() - dt.timedelta(days=1))
        issue_2 = IssueFactory.create(journal=self.journal, date_published=dt.datetime.now())
        url = reverse('public:home')
        # Run
        response = self.client.get(url)
        # Check
        self.assertEqual(response.status_code, 200)
        self.assertEqual(list(response.context['latest_issues']), [issue_2, issue_1, ])

    @unittest.mock.patch.object(feedparser, 'parse')
    def test_embeds_the_latest_news_into_the_context(self, mock_content):
        # Setup
        with open(os.path.join(FIXTURE_ROOT, 'news_rss_feed.pickle'), 'rb') as rss:
            mock_content.return_value = pickle.load(rss)

        url = reverse('public:home')
        # Run
        response = self.client.get(url)
        # Check
        self.assertEqual(response.status_code, 200)
        self.assertTrue(len(response.context['latest_news']))

    def test_embeds_the_upcoming_journals_into_the_context(self):
        # Setup
        JournalFactory.create(collection=self.collection, upcoming=False)
        url = reverse('public:home')
        # Run
        response = self.client.get(url)
        # Check
        self.assertEqual(response.status_code, 200)

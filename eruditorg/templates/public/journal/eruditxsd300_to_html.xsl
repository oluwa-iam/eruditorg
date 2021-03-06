{% load i18n %}{% load staticfiles %}<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:v="variables-node" version="2.0">
  <xsl:output method="html" indent="yes" encoding="UTF-8"/>
  <xsl:strip-space elements="*"/>

  <!--=========== VARIABLES & PARAMETERS ===========-->
  <!-- possible values for cover - 'no', 'coverpage.jpg', 'no-image' -->
  <xsl:variable name="iderudit" select="article/@idproprio"/>
  <xsl:variable name="typeudoc">
    <xsl:choose>
      <xsl:when test="article/@typeart='article'">
        <xsl:value-of select="'article'" />
      </xsl:when>
      <xsl:when test="article/@typeart='compte rendu' or article/@typeart='compterendu'">
        <xsl:value-of select="'compterendu'" />
      </xsl:when>
      <xsl:when test="starts-with(article/@typeart, 'note')">
        <xsl:value-of select="'note'" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="'autre'" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  <xsl:variable name="titreAbrege" select="article/admin/revue/titrerevabr"/>
  <xsl:variable name="uriStart">http://id.erudit.org/iderudit/</xsl:variable>
  <xsl:variable name="doiStart">http://dx.doi.org/</xsl:variable>

  <v:variables>
    {% for imid, infoimg in article.fedora_object.infoimg_dict.items %}
    <v:variable n="src-{{ imid }}" value="{{ infoimg.src }}" />
    <v:variable n="plgr-{{ imid }}" value="{{ infoimg.plgr }}" />
    {% endfor %}
  </v:variables>
  <xsl:variable name="vars" select="document('')//v:variables/v:variable" />

  <!-- Savante, culturelle, ... -->
  <xsl:param name="typecoll" />

  <!-- Eliminer les lignes vides dans le document resultant -->
  <xsl:strip-space elements="alinea"/>

  <xsl:template match="/">
    <div class="article-wrapper">
      <xsl:apply-templates select="article"/>
    </div>
  </xsl:template>

  <xsl:template match="article">

    <!-- main header -->
    <header class="row page-header-main article-header" id="article-header">

      <hgroup class="col-xs-12 child-column-fit">

        <div class="col-sm-9">
          {% if only_summary %}
          <p class="title-summary">{% trans 'Notice' %}</p>
          {% endif %}
          <xsl:if test="liminaire/grtitre/surtitre">
            <p class="title-tag">
              <xsl:apply-templates select="liminaire/grtitre/surtitre" mode="title"/>
              <xsl:apply-templates select="liminaire/grtitre/surtitreparal" mode="title"/>
            </p>
          </xsl:if>
          <h1>
            <xsl:apply-templates select="liminaire/grtitre/titre" mode="title"/>
            <xsl:apply-templates select="liminaire/grtitre/sstitre" mode="title"/>
            <xsl:apply-templates select="liminaire/grtitre/titreparal" mode="title"/>
            <xsl:apply-templates select="liminaire/grtitre/sstitreparal" mode="title"/>
            <xsl:apply-templates select="liminaire/grtitre/trefbiblio" mode="title"/>
          </h1>
          <xsl:if test="liminaire/grauteur">
            <ul class="grauteur">
              <xsl:apply-templates select="liminaire/grauteur/auteur[not(contribution[@typecontrib != 'aut'])]" mode="author"/>
            </ul>
          </xsl:if>
          <xsl:if test="liminaire/grauteur/auteur/contribution or liminaire/grauteur/auteur/affiliation or liminaire/grauteur/auteur/courriel or liminaire/grauteur/auteur/siteweb">
            <div class="affiliations akkordion" data-akkordion-single="true">
              <p class="affiliations-label akkordion-title">{% trans '…plus d’informations' %} <span class="icon ion-ios-arrow-down"></span></p>
              <ul class="akkordion-content unstyled">
                <xsl:apply-templates select="liminaire/grauteur/auteur" mode="affiliations"/>
              </ul>
            </div>
          </xsl:if>
          {% if not article_access_granted and not only_summary %}
          <div class="alert alert-warning">
            <p>
              {% blocktrans trimmed %}
              L’accès aux articles des numéros courants de cette revue est réservé aux abonnés. Toutes les archives des revues sont disponibles en libre accès. Pour plus d’informations, veuillez communiquer avec nous à l’adresse <a href="mailto:client@erudit.org?subject=Accès aux articles d’Érudit">client@erudit.org</a>.
              {% endblocktrans %}
              <br/>
              <strong>
                {% if not article.erudit_object.abstracts and can_display_first_pdf_page %}
                {% trans "Seule la première page du PDF sera affichée." %}
                {% elif article.erudit_object.abstracts %}
                {% trans "Seul le résumé sera affiché." %}
                {% elif article.is_scientific %}
                {% trans "Seuls les 600 premiers mots du texte seront affichés." %}
                {% endif %}
              </strong>
            </p>
          </div>
          {% endif %}
        </div>

        <!-- issue cover image or journal logo -->
        <div class="issue-image col-sm-3">
          {% if article.issue.has_coverpage %}
          <a href="{% url 'public:journal:issue_detail' article.issue.journal.code article.issue.volume_slug article.issue.localidentifier %}" title="{% blocktrans with journal=article.issue.journal.name %}Consulter ce numéro de la revue {{ journal }}{% endblocktrans %}">
            <img src="{% url 'public:journal:issue_coverpage' article.issue.journal.code article.issue.volume_slug article.issue.localidentifier %}" class="img-responsive issue-cover" alt="{% trans 'Couverture de' %} {% if article.issue.html_title %}{{ article.issue.html_title|safe }}, {% endif %}
              {{ article.issue.volume_title_with_pages }}, {{ article.issue.journal.name }}" />
            </a>
          {% else %}
          <a href="{% url 'public:journal:issue_detail' article.issue.journal.code article.issue.volume_slug article.issue.localidentifier %}" title="{% blocktrans with journal=article.issue.journal.name %}Consulter ce numéro de la revue {{ journal }}{% endblocktrans %}">
            <img src="{% url 'public:journal:journal_logo' article.issue.journal.code %}" class="img-responsive journal-logo" alt="{% trans 'Logo de' %} {{ article.issue.journal.name }}" />
          </a>
          {% endif %}
          {% if only_summary %}
          <a href="{% url 'public:journal:article_detail' journal_code=article.issue.journal.code issue_slug=article.issue.volume_slug issue_localid=article.issue.localidentifier localid=article.localidentifier %}" class="btn btn-primary">{% trans "Lire le texte intégral" %} <span class="ion ion-arrow-right-c"></span></a>
          {% endif %}
        </div>
      </hgroup>

      <!-- article metadata -->
      <div class="meta-article col-sm-6 border-top">

        <xsl:apply-templates select="liminaire/erratum"/>

        <dl class="mono-space idpublic">
          <dt>URI</dt>
          <dd>
            <span class="hint--top hint--no-animate" data-hint="{% blocktrans %}Cliquez pour copier l'URI de cet article.{% endblocktrans %}">
              <a href="{{ request.is_secure|yesno:'https,http' }}://{{ request.site.domain }}{% url 'public:journal:iderudit_article_detail' localid=article.localidentifier %}" class="clipboard-data">
                {{ request.is_secure|yesno:'https,http' }}://{{ request.site.domain }}{% url 'public:journal:iderudit_article_detail' localid=article.localidentifier %}
                <span class="clipboard-msg clipboard-success">{% trans "adresse copiée" %}</span>
                <span class="clipboard-msg clipboard-error">{% trans "une erreur s'est produite" %}</span>
              </a>
            </span>
          </dd>
          {% if article.issue.journal.type.code == 'S' %}
          <dt>DOI</dt>
          <dd>
            <span class="hint--top hint--no-animate" data-hint="{% blocktrans %}Cliquez pour copier le DOI de cet article.{% endblocktrans %}">
              <a href="{$doiStart}10.7202/{$iderudit}" class="clipboard-data">
                10.7202/<xsl:value-of select="$iderudit"/>
                <span class="clipboard-msg clipboard-success">{% trans "adresse copiée" %}</span>
                <span class="clipboard-msg clipboard-error">{% trans "une erreur s'est produite" %}</span>
              </a>
            </span>
          </dd>
          {% endif %}
        </dl>

        <xsl:apply-templates select="liminaire/notegen"/>
        <xsl:apply-templates select="admin/histpapier"/>

      </div>

      <!-- journal metadata -->
      <div class="meta-journal col-sm-6 border-top">
        <p>
          {% blocktrans %}<xsl:apply-templates select="../article/@typeart"/> de la revue{% endblocktrans %}
          <a href="{{ request.is_secure|yesno:'https,http' }}://{{ request.site.domain }}{% url 'public:journal:journal_detail' article.issue.journal.code %}"><xsl:value-of select="admin/revue/titrerev"/></a>
        </p>
        <p class="refpapier">
          <xsl:apply-templates select="admin/numero" mode="refpapier"/>
          <xsl:if test="admin/infoarticle/pagination">
            <xsl:apply-templates select="admin/infoarticle/pagination"/>
          </xsl:if>
          <xsl:apply-templates select="admin/numero/grtheme/theme" mode="refpapier"/>
        </p>
        <xsl:apply-templates select="admin/droitsauteur"/>
      </div>

    </header>

    <div id="article-content" class="row border-top">
      <xsl:if test="//corps">
        {% if article.erudit_object.processing == 'complet' %}
        <!-- article outline -->
        <nav class="hidden-xs hidden-sm hidden-md col-md-3 article-table-of-contents" role="navigation">
          <h2>{% trans "Plan de l’article" %}</h2>
          <ul class="unstyled">
            <li>
              <a href="#article-header">
                <em>{% trans "Retour au début" %}</em>
              </a>
            </li>
            <xsl:if test="//resume">
              <li>
                <a href="#resume">{% trans "Résumé" %}</a>
              </li>
            </xsl:if>
            {% if article_access_granted and not only_summary %}
            <xsl:if test="//section1/titre[not(@traitementparticulier='oui')]">
              <li class="article-toc--body">
                <ul class="unstyled">
                  <xsl:apply-templates select="corps/section1/titre[not(@traitementparticulier='oui')]" mode="toc-heading"/>
                </ul>
              </li>
            </xsl:if>
            {% endif %}
            <xsl:for-each select="partiesann[1]">
              {% if article_access_granted and not only_summary %}
              <xsl:if test="grannexe">
                <li>
                  <a href="#grannexe">
                    <xsl:apply-templates select="grannexe" mode="toc-heading"/>
                  </a>
                </li>
              </xsl:if>
              <xsl:if test="merci">
                <li>
                  <a href="#merci">
                    <xsl:apply-templates select="merci" mode="toc-heading"/>
                  </a>
                </li>
              </xsl:if>
              <xsl:if test="grnotebio">
                <li>
                  <a href="#grnotebio">
                    <xsl:apply-templates select="grnotebio" mode="toc-heading"/>
                  </a>
                </li>
              </xsl:if>
              <xsl:if test="grnote">
                <li>
                  <a href="#grnote">
                    <xsl:apply-templates select="grnote" mode="toc-heading"/>
                  </a>
                </li>
              </xsl:if>
              {% endif %}
              <xsl:if test="grbiblio">
                <li>
                  <a href="#grbiblio">
                    <xsl:apply-templates select="grbiblio" mode="toc-heading"/>
                  </a>
                </li>
              </xsl:if>
            </xsl:for-each>
            {% if not only_summary %}
            <xsl:if test="//figure">
              <li>
                <a href="#figures">{% trans "Liste des figures" %}</a>
              </li>
            </xsl:if>
            <xsl:if test="//tableau">
              <li>
                <a href="#tableaux">{% trans "Liste des tableaux" %}</a>
              </li>
            </xsl:if>
            {% endif %}
          </ul>
          <!-- promotional campaign -->
          <aside class="campaign">
            <h2 class="sr-only">{% trans 'On n’est jamais trop érudit.' %}</h2>
            <a href="http://jamaistrop.erudit.org/{% if LANGUAGE_CODE == 'en' %}?lang=en{% endif %}" target="_blank" class="campaign-sidebar">
              <div id="campaign-sidebar" class="campaign-sidebar {% if LANGUAGE_CODE == 'en' %}en{% endif %}">
                <img src="{% static 'img/campaign/sidebar1.png' %}" class="img-responsive"/>
              </div>
            </a>
          </aside>
        </nav>
        {% endif %}

        <!-- toolbox -->
        <aside class="pull-right hidden-xs hidden-sm toolbox-wrapper">
          <h2 class="hidden">{% trans "Boîte à outils" %}</h2>
          <ul class="unstyled toolbox">
            <li>
              <button id="tool-citation-save-{{ article.id }}" data-citation-save="#article-{{ article.id }}"{% if article.id in request.saved_citations %} style="display:none;"{% endif %}>
                <span class="erudicon erudicon-tools-save"></span>
                <span class="tools-label">{% trans "Sauvegarder" %}</span>
              </button>
              <button class="saved" id="tool-citation-remove-{{ article.id }}" data-citation-remove="#article-{{ article.id }}"{% if not article.id in request.saved_citations %} style="display:none;"{% endif %}>
                <span class="erudicon erudicon-tools-save"></span>
                <span class="tools-label">{% trans "Supprimer" %}</span>
              </button>
            </li>
            {% if article_access_granted and pdf_exists %}
            <li>
              <button id="tool-download" data-href="{% url 'public:journal:article_raw_pdf' article.issue.journal.code article.issue.volume_slug article.issue.localidentifier article.localidentifier %}">
                <span class="erudicon erudicon-tools-pdf"></span>
                <span class="tools-label">{% trans "Télécharger" %}</span>
              </button>
            </li>
            {% endif %}
            <li>
              <button id="tool-cite" data-modal-id="#id_cite_modal_{{ article.id }}">
                <span class="erudicon erudicon-tools-cite"></span>
                <span class="tools-label">{% trans "Citer cet article" %}</span>
              </button>
            </li>
            <li>
              <button id="tool-share" data-title="{{ article.title }}" data-cite="#id_cite_mla_{{ article.id }}">
                <span class="erudicon erudicon-tools-share"></span>
                <span class="tools-label">{% trans "Partager" %}</span>
              </button>
            </li>
          </ul>
        </aside>
      </xsl:if>

      <div class="full-article {% if article.erudit_object.processing == 'complet' %}col-md-7 col-md-offset-1{% else %} col-md-11{% endif %}">
        <!-- abstract -->
        <xsl:if test="//resume">
          <section id="resume" class="article-section grresume" role="complementary">
            <h2 class="hidden">{% trans "Résumé" %}</h2>
            <xsl:apply-templates select="//resume"/>
          </section>
        </xsl:if>

        {% if article_access_granted and not only_summary %}
          {% if article.erudit_object.processing == 'complet' %}
          <!-- body -->
          <section id="corps" class="article-section corps" role="main">
            <h2 class="hidden">{% trans "Corps de l’article" %}</h2>
            <xsl:apply-templates select="//corps"/>
          </section>
          {% elif article.localidentifier %}
          <object id="pdf-viewer" data="{% url 'public:journal:article_raw_pdf' article.issue.journal.code article.issue.volume_slug article.issue.localidentifier article.localidentifier%}?embed" type="application/pdf" width="100%" height="700px"></object>
          <a id="pdf-download" href="{% url 'public:journal:article_raw_pdf' article.issue.journal.code article.issue.volume_slug article.issue.localidentifier article.localidentifier%}">Télécharger le pdf</a>
          {% endif %}
        {% elif article.erudit_object.abstracts %}
        {% elif not article.erudit_object.abstracts and can_display_first_pdf_page %}
        <p>
          <object id="pdf-viewer" data="{% url 'public:journal:article_raw_pdf_firstpage' article.issue.journal.code article.issue.volume_slug article.issue.localidentifier article.localidentifier %}?embed" type="application/pdf" width="100%" height="700px"></object>
          <a id="pdf-download">Télécharger le pdf</a>
        </p>
        {% elif article.is_scientific %}
          {{ article.erudit_object.html_body|safe|truncatewords_html:600 }}
        {% endif %}


        <!-- appendices -->
        <div class="row">
          <hr/>
          {% if article.erudit_object.processing == 'minimal' %}
          <!-- promotional campaign -->
          <div class="col-md-3">
            <aside class="campaign">
              <h2 class="sr-only">{% trans 'On n’est jamais trop érudit.' %}</h2>
              <a href="http://jamaistrop.erudit.org/{% if LANGUAGE_CODE == 'en' %}?lang=en{% endif %}" target="_blank" class="campaign-sidebar">
                <div id="campaign-sidebar" class="campaign-sidebar {% if LANGUAGE_CODE == 'en' %}en{% endif %}">
                  <img src="{% static 'img/campaign/sidebar1.png' %}" class="img-responsive"/>
                </div>
              </a>
            </aside>
          </div>
          {% endif %}
          <xsl:apply-templates select="partiesann[node()]"/>
        </div>

        <!-- lists of tables & figures -->
        {% if not only_summary %}
        <xsl:if test="//figure">
          <section id="figures" class="article-section figures" role="complementary">
            <h2>{% trans "Liste des figures" %}</h2>
            <xsl:apply-templates select="//figure/objetmedia" mode="liste"/>
          </section>
        </xsl:if>

        <xsl:if test="//tableau">
          <section id="tableaux" class="article-section tableaux" role="complementary">
            <h2>{% trans "Liste des tableaux" %}</h2>
            <xsl:apply-templates select="//tableau/objetmedia" mode="liste"/>
          </section>
        </xsl:if>
        {% endif %}

      </div>
    </div>

  </xsl:template>

  <!--=========== TEMPLATES ===========-->

  <!--**** HEADER ***-->
  <!-- identifiers -->
  <xsl:template match="idpublic[@scheme = 'doi']">
    <xsl:text>&#x0020;</xsl:text>
    <a href="{$doiStart}{.}" class="refbiblio-link {name()}" target="_blank">
      <xsl:if test="contains( . , '10.7202')">
        <img src="{% static 'svg/symbole-erudit.svg' %}" title="DOI Érudit" alt="Icône pour les DOIs Érudit" class="erudit-doi"/>
      </xsl:if>
      <xsl:text>DOI:</xsl:text>
      <xsl:value-of select="."/>
    </a>
  </xsl:template>

  <xsl:template match="idpublic[@scheme='uri']">
    <a href="{$uriStart}{.}" class="refbiblio-link {name()}" target="_blank">
      <xsl:text>URI:</xsl:text>
      <xsl:value-of select="."/>
    </a>
  </xsl:template>

  <!-- article type -->
  <xsl:template match="@typeart">
    <xsl:choose>
      <xsl:when test="$typeudoc = 'article'">{% trans "Un article" %}</xsl:when>
      <xsl:when test="$typeudoc = 'compterendu'">{% trans "Un compte rendu" %}</xsl:when>
      <xsl:when test="$typeudoc = 'note'">{% trans "Une note" %}</xsl:when>
      <xsl:otherwise>{% trans "Un document" %}</xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- issue-level section title / subhead -->
  <xsl:template match="liminaire/grtitre/surtitre | liminaire/grtitre/surtitreparal" mode="title">
    <xsl:for-each select="child::node()">
      <span class="surtitre">
        <xsl:apply-templates select="."/>
      </span>
    </xsl:for-each>
  </xsl:template>

  <!-- article title(s) -->
  <xsl:template match="article/liminaire/grtitre/titre | article/liminaire/grtitre/trefbiblio | article/liminaire/grtitre/sstitre" mode="title">
    <span class="{name()}">
      <xsl:apply-templates/>
    </span>
  </xsl:template>

  <!-- alternate title(s) for multilingual articles -->
  <xsl:template match="article/liminaire/grtitre/titreparal | article/liminaire/grtitre/sstitreparal" mode="title">
    <xsl:if test="not(//resume)">
      <span class="{name()}">
        <xsl:apply-templates/>
      </span>
    </xsl:if>
  </xsl:template>

  <!-- author(s) - person or organisation -->
  <xsl:template match="auteur[not(contribution[@typecontrib = 'trl'])]" mode="author">
    <li class="{name()}">
      <xsl:choose>
        <xsl:when test="nompers">
          <span class="nompers">
            <xsl:call-template name="element_nompers_affichage">
              <xsl:with-param name="nompers" select="nompers[1]"/>
            </xsl:call-template>
            <xsl:if test="nompers[2][@typenompers = 'pseudonyme']">
              <xsl:text>, </xsl:text>
              <xsl:call-template name="element_nompers_affichage">
                <xsl:with-param name="nompers" select="nompers[2]"/>
              </xsl:call-template>
            </xsl:if>
          </span>
        </xsl:when>
        <xsl:when test="nomorg/child::node()">
          <span class="nomorg">
            <xsl:call-template name="syntaxe_texte_affichage">
              <xsl:with-param name="texte" select="nomorg"/>
            </xsl:call-template>
            <xsl:if test="membre">
              <xsl:text>&#160;(</xsl:text>
              <xsl:for-each select="membre">
                <xsl:call-template name="element_nompers_affichage">
                  <xsl:with-param name="nompers" select="nompers"></xsl:with-param>
                </xsl:call-template>
                <xsl:if test="position() != last()"><xsl:text>, </xsl:text></xsl:if>
              </xsl:for-each>)
            </xsl:if>
          </span>
        </xsl:when>
      </xsl:choose>
      <xsl:choose>
        <xsl:when test="position() = last()-1">
          <xsl:text> {% trans 'et' %} </xsl:text>
        </xsl:when>
        <xsl:when test="position() != last()">
          <xsl:text>, </xsl:text>
        </xsl:when>
      </xsl:choose>
    </li>
  </xsl:template>

  <!-- author affiliations -->
  <xsl:template match="auteur" mode="affiliations">
    <xsl:if test="contribution | affiliation | courriel | siteweb">
      <xsl:for-each select=".">
        <li class="auteur-affiliation">
          <p>
            <xsl:apply-templates select="nompers | nomorg | contribution | affiliation/alinea | courriel | siteweb" mode="affiliations"/>
          </p>
        </li>
      </xsl:for-each>
    </xsl:if>
  </xsl:template>

  <xsl:template match="nompers | nomorg | contribution | affiliation/alinea | courriel | siteweb" mode="affiliations">
    <xsl:for-each select=".">
      <xsl:choose>
        <xsl:when test="self::nompers">
          <strong>
            <xsl:call-template name="element_nompers_affichage">
              <xsl:with-param name="nompers" select="self::nompers[1]"/>
            </xsl:call-template>
            <xsl:if test="self::nompers[2][@typenompers = 'pseudonyme']">
              <xsl:text>, </xsl:text>
              <xsl:call-template name="element_nompers_affichage">
                <xsl:with-param name="nompers" select="self::nompers[2]"/>
              </xsl:call-template>
            </xsl:if>
          </strong>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
    <xsl:if test="position() != last()"><br/></xsl:if>
  </xsl:template>

  <!-- admin notes: errata, article history, editor's notes... -->
  <xsl:template match="article/liminaire/notegen | article/liminaire/erratum | admin/histpapier">
    <div class="{name()}">
      <xsl:if test="titre">
        <h2>
          <xsl:apply-templates select="titre"/>
        </h2>
      </xsl:if>
      <xsl:apply-templates select="*[not(self::titre)]"/>
    </div>
  </xsl:template>

  <!-- issue volume / number -->
  <xsl:template match="admin/numero" mode="refpapier">
    <span class="volumaison">
      <xsl:for-each select="volume | nonumero[1] | pub/periode | pub/annee | pagination">
        <xsl:apply-templates select="."/>
        <xsl:if test="position() != last()">
          <xsl:text>, </xsl:text>
        </xsl:if>
      </xsl:for-each>
    </span>
  </xsl:template>

  <xsl:template match="numero/volume">
    <span class="{name()}">
      <xsl:text{% blocktrans %}>Volume&#160;{% endblocktrans %}</xsl:text>
      <xsl:value-of select="."/>
    </span>
  </xsl:template>

  <xsl:template match="numero/nonumero[1]">
    <!-- template for first occurence of nonumero only; this allows the display of issues like Numéro 3-4 or Numéro 1-2-3 -->
    <span class="{name()}">
      <xsl:text>{% blocktrans %}Numéro&#160;{% endblocktrans %}</xsl:text>
      <!-- check if there are nonumero siblings -->
      <xsl:for-each select="parent::numero/nonumero">
        <xsl:value-of select="."/>
        <xsl:if test="position() != last()">
          <xsl:text>–</xsl:text>
        </xsl:if>
      </xsl:for-each>
    </span>
  </xsl:template>

  <xsl:template match="numero/periode | numero/annee">
    <span class="{name()}">
      <xsl:value-of select="."/>
    </span>
  </xsl:template>

  <xsl:template match="pagination">
    <span class="{name()}">
      <xsl:if test="ppage | dpage != '0'">
        <xsl:text>, </xsl:text>
        <xsl:choose>
          <xsl:when test="ppage = dpage">p.&#160;<xsl:value-of select="ppage"/></xsl:when>
          <xsl:otherwise>pp.&#160;<xsl:value-of select="ppage"/>–<xsl:value-of select="dpage"/></xsl:otherwise>
        </xsl:choose>
      </xsl:if>
    </span>
  </xsl:template>

  <xsl:template match="ppage | dpage">
    <span class="{name()}">
      <xsl:value-of select="."/>
    </span>
  </xsl:template>

  <!-- themes -->
  <xsl:template match="admin/numero/grtheme/theme" mode="refpapier">
    <span class="{name()}">
      <xsl:apply-templates select="."/>
    </span>
  </xsl:template>

  <!-- copyright -->
  <xsl:template match="droitsauteur">
    <p class="{name()}">
      <small><xsl:value-of select="."/></small>
    </p>
  </xsl:template>

  <!-- abstracts -->
  <xsl:template match="//resume">
    <section id="{name()}-{@lang}" class="{name()}">
      <xsl:if test="@lang='fr'">
        <h2>
          <xsl:choose>
            <xsl:when test="titre">
              <xsl:value-of select="titre"/>
            </xsl:when>
            <xsl:otherwise>
              Résumé
            </xsl:otherwise>
          </xsl:choose>
        </h2>
        <p>
          <xsl:apply-templates select="*[not(self::titre)]"/>
        </p>
        <xsl:if test="//grmotcle[@lang='fr']/motcle">
          <div class="motscles">
            <strong>Mots clés : </strong>
            <ul class="inline">
              <xsl:for-each select="//grmotcle[@lang='fr']/motcle">
                <li class="keyword">
                  <xsl:apply-templates/>
                  <xsl:if test="position() != last()">
                    <xsl:text>, </xsl:text>
                  </xsl:if>
                </li>
              </xsl:for-each>
            </ul>
          </div>
        </xsl:if>
      </xsl:if>
      <xsl:if test="@lang='en'">
        <h2>
          <xsl:choose>
            <xsl:when test="titre">
              <xsl:value-of select="titre"/>
            </xsl:when>
            <xsl:otherwise>
              Abstract
            </xsl:otherwise>
          </xsl:choose>
        </h2>
        <xsl:apply-templates select="//grtitre/titreparal[@lang='en']" mode="abstract"/>
        <p>
          <xsl:apply-templates select="*[not(self::titre)]"/>
        </p>
        <xsl:if test="//grmotcle[@lang='en']/motcle">
          <div class="motscles">
            <strong>Keywords : </strong>
            <ul class="inline">
              <xsl:for-each select="//grmotcle[@lang='en']/motcle">
                <li class="keyword">
                  <xsl:apply-templates/>
                  <xsl:if test="position() != last()">
                    <xsl:text>, </xsl:text>
                  </xsl:if>
                </li>
              </xsl:for-each>
            </ul>
          </div>
        </xsl:if>
      </xsl:if>
      <xsl:if test="@lang='es'">
        <h2>
          <xsl:choose>
            <xsl:when test="titre">
              <xsl:value-of select="titre"/>
            </xsl:when>
            <xsl:otherwise>
              Resumen
            </xsl:otherwise>
          </xsl:choose>
        </h2>
        <xsl:apply-templates select="//grtitre/titreparal[@lang='es']" mode="abstract"/>
        <p>
          <xsl:apply-templates select="*[not(self::titre)]"/>
        </p>
        <xsl:if test="//grmotcle[@lang='es']/motcle">
          <div class="motscles">
            <strong>Palabras clave : </strong>
            <ul class="inline">
              <xsl:for-each select="//grmotcle[@lang='es']/motcle">
                <li class="keyword">
                  <xsl:apply-templates/>
                  <xsl:if test="position() != last()">
                    <xsl:text>, </xsl:text>
                  </xsl:if>
                </li>
              </xsl:for-each>
            </ul>
          </div>
        </xsl:if>
      </xsl:if>
    </section>
  </xsl:template>

  <xsl:template match="titreparal" mode="abstract">
    <h3 class="{name()}">
      <xsl:apply-templates/>
    </h3>
  </xsl:template>

  <xsl:template match="resume/alinea">
    <xsl:apply-templates/>
  </xsl:template>

  <!--*** ARTICLE OUTLINE ***-->
  <xsl:template match="article/corps/section1/titre[not(@traitementparticulier='oui')]" mode="toc-heading">
    <li>
      <a href="#{../@id}">
        <xsl:apply-templates mode="toc-heading"/>
      </a>
    </li>
  </xsl:template>

  <xsl:template match="renvoi | liensimple" mode="toc-heading">
    <!-- do not display anything -->
  </xsl:template>

  <xsl:template match="marquage" mode="toc-heading">
    <xsl:choose>
      <xsl:when test="@typemarq='gras'">
        <strong>
          <xsl:apply-templates/>
        </strong>
      </xsl:when>
      <xsl:when test="@typemarq='italique'">
        <em>
          <xsl:apply-templates/>
        </em>
      </xsl:when>
      <xsl:when test="@typemarq='taillep'">
        <small>
          <xsl:apply-templates/>
        </small>
      </xsl:when>
      <xsl:otherwise>
        <span class="{@typemarq}">
          <xsl:apply-templates/>
        </span>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="exposant" mode="toc-heading">
    <xsl:element name="sup">
      <xsl:if test="@traitementparticulier = 'oui'">
        <xsl:attribute name="class">
          <xsl:text>{% trans "special" %}</xsl:text>
        </xsl:attribute>
      </xsl:if>
      <xsl:call-template name="syntaxe_texte_affichage">
        <xsl:with-param name="texte" select="."/>
      </xsl:call-template>
    </xsl:element>
  </xsl:template>

  <xsl:template match="indice" mode="toc-heading">
    <xsl:element name="sub">
      <xsl:if test="@traitementparticulier">
        <xsl:attribute name="class">
          <xsl:text>{% trans "special" %}</xsl:text>
        </xsl:attribute>
      </xsl:if>
      <xsl:call-template name="syntaxe_texte_affichage">
        <xsl:with-param name="texte" select="."/>
      </xsl:call-template>
    </xsl:element>
  </xsl:template>

  <xsl:template match="grannexe | grnotebio | grnote | merci | grbiblio"  mode="toc-heading">
    <xsl:if test="self::grannexe">
      <xsl:choose>
        <xsl:when test="titre">
          <xsl:value-of select="titre"/>
        </xsl:when>
        <xsl:when test="count(annexe) = 1">{% trans "Annexe" %}</xsl:when>
        <xsl:otherwise>{% trans "Annexes" %}</xsl:otherwise>
      </xsl:choose>
    </xsl:if>
    <xsl:if test="self::grnotebio">
      <xsl:choose>
        <xsl:when test="titre">
          <xsl:value-of select="titre"/>
        </xsl:when>
        <xsl:when test="count(notebio) = 1">{% trans "Note biographique" %}</xsl:when>
        <xsl:otherwise>{% trans "Notes biographiques" %}</xsl:otherwise>
      </xsl:choose>
    </xsl:if>
    <xsl:if test="self::grnote">
      <xsl:choose>
        <xsl:when test="titre">
          <xsl:value-of select="titre"/>
        </xsl:when>
        <xsl:when test="count(note) = 1">{% trans "Note" %}</xsl:when>
        <xsl:otherwise>{% trans "Notes" %}</xsl:otherwise>
      </xsl:choose>
    </xsl:if>
    <xsl:if test="self::merci">
      <xsl:choose>
        <xsl:when test="titre">
          <xsl:value-of select="titre"/>
        </xsl:when>
        <xsl:otherwise>{% trans "Remerciements" %}</xsl:otherwise>
      </xsl:choose>
    </xsl:if>
    <xsl:if test="self::grbiblio">
      <xsl:choose>
        <xsl:when test="count(biblio) = 1">{% trans "Bibliographie" %}</xsl:when>
        <xsl:otherwise>{% trans "Bibliographies" %}</xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:template>
  <!--*** BODY ***-->
  <xsl:template match="corps">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="section1">
    <section id="{@id}">
      <xsl:if test="titre">
        <xsl:element name="h2">
          <xsl:if test="titre/@traitementparticulier">
            <xsl:attribute name="class">{% trans "special" %}</xsl:attribute>
          </xsl:if>
          <xsl:apply-templates select="titre"/>
        </xsl:element>
      </xsl:if>
      <xsl:apply-templates select="*[not(self::no)][not(self::titre)][not(self::titreparal)]"/>
    </section>
  </xsl:template>
  <xsl:template match="section2">
    <section id="{@id}">
      <xsl:if test="titre">
        <xsl:element name="h3">
          <xsl:if test="titre/@traitementparticulier">
            <xsl:attribute name="class">{% trans "special" %}</xsl:attribute>
          </xsl:if>
          <xsl:apply-templates select="titre"/>
        </xsl:element>
      </xsl:if>
      <xsl:apply-templates select="*[not(self::no)][not(self::titre)][not(self::titreparal)]"/>
    </section>
  </xsl:template>
  <xsl:template match="section3">
    <section id="{@id}">
      <xsl:if test="titre">
        <xsl:element name="h4">
          <xsl:if test="titre/@traitementparticulier">
            <xsl:attribute name="class">{% trans "special" %}</xsl:attribute>
          </xsl:if>
          <xsl:apply-templates select="titre"/>
        </xsl:element>
      </xsl:if>
      <xsl:apply-templates select="*[not(self::no)][not(self::titre)][not(self::titreparal)]"/>
    </section>
  </xsl:template>
  <xsl:template match="section4">
    <section id="{@id}">
      <xsl:if test="titre">
        <xsl:element name="h5">
          <xsl:if test="titre/@traitementparticulier">
            <xsl:attribute name="class">{% trans "special" %}</xsl:attribute>
          </xsl:if>
          <xsl:apply-templates select="titre"/>
        </xsl:element>
      </xsl:if>
      <xsl:apply-templates select="*[not(self::no)][not(self::titre)][not(self::titreparal)]"/>
    </section>
  </xsl:template>
  <xsl:template match="section5">
    <section id="{@id}">
      <xsl:if test="titre">
        <xsl:element name="h6">
          <xsl:if test="titre/@traitementparticulier">
            <xsl:attribute name="class">{% trans "special" %}</xsl:attribute>
          </xsl:if>
          <xsl:apply-templates select="titre"/>
        </xsl:element>
      </xsl:if>
      <xsl:apply-templates select="*[not(self::no)][not(self::titre)][not(self::titreparal)]"/>
    </section>
  </xsl:template>
  <xsl:template match="section6">
    <section id="{@id}">
      <xsl:if test="titre">
        <xsl:element name="h6">
          <xsl:attribute name="class">h7</xsl:attribute>
          <xsl:if test="titre/@traitementparticulier">
            <xsl:attribute name="class">{% trans "special" %}</xsl:attribute>
          </xsl:if>
          <xsl:apply-templates select="titre"/>
        </xsl:element>
      </xsl:if>
      <xsl:apply-templates select="*[not(self::no)][not(self::titre)][not(self::titreparal)]"/>
    </section>
  </xsl:template>
  <xsl:template match="para">
    <div class="{name()}" id="{@id}">
      <xsl:apply-templates select="no" mode="para"/>
      <xsl:apply-templates select="*[not(self::no)]"/>
    </div>
  </xsl:template>
  <xsl:template match="alinea">
    <p class="{name()}">
      <xsl:apply-templates/>
    </p>
  </xsl:template>
  <xsl:template match="no" mode="para"></xsl:template>
  <xsl:template match="section1/alinea|section2/alinea|section3/alinea|section4/alinea|section5/alinea|section6/alinea|grannexe/alinea"  priority="1">
    <p class="horspara">
      <xsl:apply-templates/>
    </p>
  </xsl:template>
  <xsl:template match="no">
    <xsl:apply-templates/>
  </xsl:template>
  <xsl:template match="no" mode="liste">
    <span class="no">
      <xsl:apply-templates select="*[not(self::renvoi)]"/>
    </span>
  </xsl:template>
  <xsl:template match="legende/titre | legende/sstitre">
    <p class="legende">
      <xsl:for-each select=".">
        <strong class="{name()}">
          <xsl:apply-templates/>
        </strong>
      </xsl:for-each>
    </p>
  </xsl:template>
  <xsl:template match="legende/titre | legende/sstitre" mode="liste">
    <div class="legende">
      <xsl:for-each select=".">
        <div class="{name()}">
          <xsl:apply-templates select="*[not(self::renvoi)]"/>
        </div>
      </xsl:for-each>
    </div>
  </xsl:template>
  <xsl:template match="ligne">
    <xsl:apply-templates/>
    <br/>
  </xsl:template>
  <xsl:template match="titre">
    <xsl:apply-templates/>
  </xsl:template>
  <xsl:template match="elemliste">
    <li>
      <xsl:apply-templates/>
    </li>
  </xsl:template>

  <!-- blockquotes, dedications, epigraphs, verbatims -->
  <xsl:template match="bloccitation | dedicace | epigraphe | verbatim">
    <blockquote class="{name()} {@typeverb}">
      <xsl:apply-templates/>
    </blockquote>
  </xsl:template>

  <xsl:template match="bloccitation/source | dedicace/source | epigraphe/source | verbatim/source">
    <cite class="source">
      <xsl:apply-templates/>
    </cite>
  </xsl:template>

  <xsl:template match="bloc">
    <p class="bloc {@alignh}">
      <xsl:apply-templates/>
    </p>
  </xsl:template>

  <xsl:template match="bloc/ligne">
    <xsl:apply-templates/>
    <br/>
  </xsl:template>

  <!-- figures & tables -->
  <xsl:template match="grfigure|grtableau">
    <div class="{name()}" id="{@id}">
      <xsl:apply-templates/>
    </div>
  </xsl:template>

  <xsl:template match="figure|tableau">
    <xsl:apply-templates select="objetmedia"/>
  </xsl:template>

  <xsl:template match="figure/objetmedia|tableau/objetmedia">
    <xsl:variable name="imgSrcId" select="concat('src-', image/@id)"/>
    <xsl:variable name="imgSrc" select="$vars[@n = $imgSrcId]/@value" />
    <xsl:variable name="imgPlGrId" select="concat('plgr-', image/@id)"/>
    <xsl:variable name="imgPlGr" select="$vars[@n = $imgPlGrId]/@value" />
    <figure class="{name(..)}" id="{../@id}">
      <figcaption>
        <xsl:apply-templates select="../no"/>
        <xsl:apply-templates select="../legende/titre | ../legende/sstitre"/>
        <xsl:apply-templates select="../legende/alinea | ../legende/bloccitation | ../legende/listenonord | ../legende/listeord | ../legende/listerelation | ../legende/objetmedia | ../legende/refbiblio | ../legende/tabtexte | ../legende/verbatim"/>
        <xsl:apply-templates select="../notefig|../notetabl"/>
        <xsl:apply-templates select="../source"/>
      </figcaption>
      <a href="{{ request.get_full_path }}media/{$imgPlGr}" class="lightbox"  title="{normalize-space(../legende)}">
        <img src="{{ request.get_full_path }}media/{$imgPlGr}" alt="{normalize-space(../legende)}" class="img-responsive"/>
      </a>
      <p class="voirliste">
        <a href="#li{../@id}">{% blocktrans %}-> Voir la liste des <xsl:if test="parent::figure">figures</xsl:if><xsl:if test="parent::tableau">tableaux</xsl:if>{% endblocktrans %}</a>
      </p>
    </figure>
  </xsl:template>

  <!-- equations, examples & insets/boxed text -->
  <xsl:template match="grencadre|grequation|grexemple">
    <aside class="{name()}">
      <xsl:apply-templates select="no"/>
      <xsl:apply-templates select="legende"/>
      <xsl:apply-templates select="*[not(self::no)][not(self::legende)][not(self::titreparal)]"/>
    </aside>
  </xsl:template>
  <xsl:template match="encadre">
    <aside class="encadre type{@type}">
      <xsl:apply-templates/>
    </aside>
  </xsl:template>

  <!-- notes within equations, examples and insets -->
  <xsl:template match="noteenc|noteeq|noteex">
    <xsl:call-template name="noteillustrationtype">
      <xsl:with-param name="noteIllustration" select="."/>
    </xsl:call-template>
  </xsl:template>
  <xsl:template match="equation">
    <xsl:variable name="valeurID" select="@id"/>
    <aside class="equation">
      <!-- Les numéros -->
      <xsl:for-each select="no">
        <span class="no">
          <xsl:call-template name="syntaxe_texte_affichage">
            <xsl:with-param name="texte" select="."/>
          </xsl:call-template>
        </span>
      </xsl:for-each>
      <!-- L'équation proprement dite -->
      <xsl:for-each        select="node()[ name() = 'alinea' or name() = 'bloccitation' or name() = 'listenonord' or name() = 'listeord' or name() = 'listerelation' or        name() = 'objetmedia' or        name() = 'refbiblio' or        name() = 'verbatim']">
        <xsl:apply-templates select="."/>
      </xsl:for-each>
      <!-- Les légendes -->
      <xsl:if test="legende">
        <div class="legende">
          <xsl:for-each select="legende">
            <xsl:apply-templates/>
          </xsl:for-each>
        </div>
      </xsl:if>
      <xsl:for-each select="node()[name() = 'noteeq' or name() = 'source']">
        <xsl:apply-templates select="."/>
      </xsl:for-each>
    </aside>
  </xsl:template>
  <xsl:template match="exemple">
    <aside class="exemple">
      <xsl:apply-templates select="no"/>
      <xsl:apply-templates select="legende"/>
      <xsl:for-each select="node()[name() != '' and name() != 'no' and name() != 'legende']">
        <xsl:apply-templates select="."/>
      </xsl:for-each>
    </aside>
  </xsl:template>

  <!-- media objects -->
  <xsl:template match="objetmedia/audio">
    <xsl:variable name="nomAud" select="@*[local-name()='href']"/>
    <audio id="{@id}" class="img-responsive" preload="metadata" controls="controls">
      <source src="http://erudit.org/media/{$titreAbrege}/{$iderudit}/{$nomAud}" type="{@typemime}"/>
    </audio>
  </xsl:template>
  <xsl:template match="objetmedia/image">
    <xsl:variable name="nomImg" select="@*[local-name()='href']"/>
    <span class="lien_img">
      <img src="{{ request.get_full_path }}media/{$nomImg}" class="objetmedia_img"/>
    </span>
  </xsl:template>
  <xsl:template match="objetmedia/texte">
    <div class="objetTexte">
      <xsl:apply-templates/>
    </div>
  </xsl:template>
  <xsl:template match="objetmedia/video">
    <xsl:variable name="videohref" select="@*[local-name()='href']"/>
    <xsl:variable name="nomVid" select="substring-before($videohref, '.')"/>
    <video id="{@id}" class="img-responsive" preload="metadata" controls="controls">
      <source src="http://erudit.org/media/{$titreAbrege}/{$iderudit}/{$nomVid}.mp4" type="video/mp4"/>
    </video>
  </xsl:template>

  <!-- grobjet & objet -->
  <xsl:template match="grobjet">
    <xsl:apply-templates/>
  </xsl:template>
  <xsl:template match="objet">
    <div class="objet">
      <xsl:apply-templates/>
    </div>
  </xsl:template>

  <!-- lists -->
  <xsl:template match="listenonord">
    <xsl:variable name="signe" select="@signe"/>
    <xsl:choose>
      <xsl:when test="@nbcol">
        <!-- listenonord multi-colonnes -->
        <xsl:variable name="elemlistes" select="elemliste"/>
        <xsl:variable name="nbElems" select="count($elemlistes)"/>
        <xsl:variable name="nbCols" select="@nbcol"/>
        <xsl:variable name="divClass" select="concat('nbcol', $nbCols)"/>
        <xsl:variable name="quotient" select="floor($nbElems div $nbCols)"/>
        <xsl:variable name="reste" select="$nbElems mod $nbCols"/>
        <!-- maximum 5 colonnes -->
        <div class="multicolonne">
          <xsl:variable name="arret1" select="$quotient + number($reste &gt; 0)"/>
          <div class="{$divClass}">
            <ul class="{$signe}">
              <xsl:for-each select="elemliste[position() &gt; 0 and position() &lt;= $arret1]">
                <xsl:apply-templates select="."/>
              </xsl:for-each>
            </ul>
          </div>
          <xsl:if test="$nbCols &gt;= 2">
            <xsl:variable name="arret2" select="$arret1 + $quotient + number($reste &gt; 1)"/>
            <div class="{$divClass}">
              <ul class="{$signe}">
                <xsl:for-each select="elemliste[position() &gt; $arret1 and position() &lt;= $arret2]">
                  <xsl:apply-templates select="."/>
                </xsl:for-each>
              </ul>
            </div>
            <xsl:if test="$nbCols &gt;= 3">
              <xsl:variable name="arret3" select="$arret2 + $quotient + number($reste &gt; 2)"/>
              <div class="{$divClass}">
                <ul class="{$signe}">
                  <xsl:for-each select="elemliste[position() &gt; $arret2 and position() &lt;= $arret3]">
                    <xsl:apply-templates select="."/>
                  </xsl:for-each>
                </ul>
              </div>
              <xsl:if test="$nbCols &gt;= 4">
                <xsl:variable name="arret4" select="$arret3 + $quotient + number($reste &gt; 3)"/>
                <div class="{$divClass}">
                  <ul class="{$signe}">
                    <xsl:for-each select="elemliste[position() &gt; $arret3 and position() &lt;= $arret4]">
                      <xsl:apply-templates select="."/>
                    </xsl:for-each>
                  </ul>
                </div>
                <xsl:if test="$nbCols &gt;= 5">
                  <xsl:variable name="arret5" select="$arret4 + $quotient + number($reste &gt; 4)"/>
                  <div class="{$divClass}">
                    <ul class="{$signe}">
                      <xsl:for-each select="elemliste[position() &gt; $arret4 and position() &lt;= $arret5]">
                        <xsl:apply-templates select="."/>
                      </xsl:for-each>
                    </ul>
                  </div>
                </xsl:if>
              </xsl:if>
            </xsl:if>
          </xsl:if>
        </div>
      </xsl:when>
      <xsl:otherwise>
        <!-- listenonord 1 colonne -->
        <ul class="{@signe}">
          <xsl:apply-templates/>
        </ul>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="listeord">
    <xsl:variable name="numeration" select="@numeration"/>
    <xsl:variable name="start">
      <xsl:choose>
        <xsl:when test="@compteur">
          <xsl:value-of select="@compteur"/>
        </xsl:when>
        <xsl:otherwise>1</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="@nbcol">
        <!-- listeord multi-colonnes -->
        <xsl:variable name="elemlistes" select="elemliste"/>
        <xsl:variable name="nbElems" select="count($elemlistes)"/>
        <xsl:variable name="nbCols" select="@nbcol"/>
        <xsl:variable name="divClass" select="concat('nbcol', $nbCols)"/>
        <xsl:variable name="quotient" select="floor($nbElems div $nbCols)"/>
        <xsl:variable name="reste" select="$nbElems mod $nbCols"/>
        <!-- maximum 5 colonnes -->
        <div class="multicolonne">
          <xsl:variable name="arret1" select="$quotient + number($reste &gt; 0)"/>
          <div class="{$divClass}">
            <ol class="{$numeration}" start="{$start}">
              <xsl:for-each select="elemliste[position() &gt; 0 and position() &lt;= $arret1]">
                <xsl:apply-templates select="."/>
              </xsl:for-each>
            </ol>
          </div>
          <xsl:if test="$nbCols &gt;= 2">
            <xsl:variable name="arret2" select="$arret1 + $quotient + number($reste &gt; 1)"/>
            <div class="{$divClass}">
              <ol class="{$numeration}" start="{$start + $arret1}">
                <xsl:for-each select="elemliste[position() &gt; $arret1 and position() &lt;= $arret2]">
                  <xsl:apply-templates select="."/>
                </xsl:for-each>
              </ol>
            </div>
            <xsl:if test="$nbCols &gt;= 3">
              <xsl:variable name="arret3" select="$arret2 + $quotient + number($reste &gt; 2)"/>
              <div class="{$divClass}">
                <ol class="$numeration" start="{$start + $arret2}">
                  <xsl:for-each select="elemliste[position() &gt; $arret2 and position() &lt;= $arret3]">
                    <xsl:apply-templates select="."/>
                  </xsl:for-each>
                </ol>
              </div>
              <xsl:if test="$nbCols &gt;= 4">
                <xsl:variable name="arret4" select="$arret3 + $quotient + number($reste &gt; 3)"/>
                <div class="{$divClass}">
                  <ol class="$numeration" start="{$start + $arret3}">
                    <xsl:for-each select="elemliste[position() &gt; $arret3 and position() &lt;= $arret4]">
                      <xsl:apply-templates select="."/>
                    </xsl:for-each>
                  </ol>
                </div>
                <xsl:if test="$nbCols &gt;= 5">
                  <xsl:variable name="arret5" select="$arret4 + $quotient + number($reste &gt; 4)"/>
                  <div class="{$divClass}">
                    <ol class="$numeration" start="{$start + $arret4}">
                      <xsl:for-each select="elemliste[position() &gt; $arret4 and position() &lt;= $arret5]">
                        <xsl:apply-templates select="."/>
                      </xsl:for-each>
                    </ol>
                  </div>
                </xsl:if>
              </xsl:if>
            </xsl:if>
          </xsl:if>
        </div>
      </xsl:when>
      <xsl:otherwise>
        <!-- listeord 1 colonne -->
        <xsl:element name="ol">
          <xsl:attribute name="class">
            <xsl:value-of select="@numeration"/>
          </xsl:attribute>
          <xsl:if test="@compteur">
            <xsl:attribute name="start">
              <xsl:value-of select="$start"/>
            </xsl:attribute>
          </xsl:if>
          <xsl:apply-templates/>
        </xsl:element>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="listerelation">
    <!-- Syntaxe (#PCDATA | %texte;)* mode affichage -->
    <xsl:variable name="type" select="@type"/>
    <xsl:variable name="numeration" select="@numeration"/>
    <xsl:variable name="tableClass" select="concat( 'listerelation type', $type )"/>
    <xsl:variable name="nos" select="no"/>
    <xsl:variable name="lrsources" select="lrsource"/>
    <xsl:variable name="lrcibles" select="lrcible"/>
    <xsl:variable name="symbole" select="@symbole"/>
    <xsl:choose>
      <xsl:when test="@nbcol">
        <!-- listerelation colonnes multiples (2) -->
        <xsl:variable name="nbCols" select="@nbcol"/>
        <xsl:variable name="divClass" select="concat('nbcol', $nbCols)"/>
        <xsl:variable name="nbElems" select="count($lrsources)"/>
        <xsl:variable name="quotient" select="floor($nbElems div $nbCols)"/>
        <xsl:variable name="reste" select="$nbElems mod $nbCols"/>
        <xsl:variable name="arret1" select="$quotient + number( $reste &gt; 0 )"/>
        <div class="multicolonne">
          <xsl:choose>
            <xsl:when test="$type &lt; 4">
              <div class="{$divClass}">
                <table class="{$tableClass}">
                  <xsl:for-each select="$lrsources[ position() &lt;= $arret1]">
                    <xsl:variable name="seq" select="position()"/>
                    <tr>
                      <xsl:if test="$nos">
                        <td class="lrno">
                          <p>
                            <xsl:call-template name="syntaxe_texte_affichage">
                              <xsl:with-param name="texte" select="$nos[$seq]"/>
                            </xsl:call-template>
                          </p>
                        </td>
                      </xsl:if>
                      <td class="lrsource">
                        <xsl:apply-templates/>
                      </td>
                      <xsl:if test="$symbole != ''">
                        <td class="centre_symbole">
                          <span>
                            <xsl:value-of select="$symbole"/>
                          </span>
                        </td>
                      </xsl:if>
                      <td class="lrcible">
                        <xsl:apply-templates select="$lrcibles[$seq]"/>
                      </td>
                    </tr>
                  </xsl:for-each>
                </table>
              </div>
              <xsl:if test="$arret1 &lt; $nbElems">
                <div class="$divClass">
                  <table class="{$tableClass}">
                    <xsl:for-each select="$lrsources[ (position() &gt; $arret1) and (position() &lt;= $nbElems) ]">
                      <xsl:variable name="seq" select="position()"/>
                      <tr>
                        <xsl:if test="$nos">
                          <td class="lrno">
                            <p>
                              <xsl:call-template name="syntaxe_texte_affichage">
                                <xsl:with-param name="texte" select="$nos[$arret1 + $seq]"/>
                              </xsl:call-template>
                            </p>
                          </td>
                        </xsl:if>
                        <td class="lrsource">
                          <xsl:apply-templates/>
                        </td>
                        <xsl:if test="$symbole != ''">
                          <td class="centre_symbole">
                            <span>
                              <xsl:value-of select="$symbole"/>
                            </span>
                          </td>
                        </xsl:if>
                        <td class="lrcible">
                          <xsl:apply-templates select="$lrcibles[$arret1 + $seq]"/>
                        </td>
                      </tr>
                    </xsl:for-each>
                  </table>
                </div>
              </xsl:if>
            </xsl:when>
            <xsl:otherwise>
              <div class="{$divClass}">
                <table class="{$tableClass}">
                  <xsl:for-each select="$lrsources[ position() &lt;= $arret1]">
                    <xsl:variable name="seq" select="position()"/>
                    <tr>
                      <xsl:if test="$nos">
                        <td class="lrno" rowspan="2">
                          <p>
                            <xsl:call-template name="syntaxe_texte_affichage">
                              <xsl:with-param name="texte" select="$nos[$seq]"/>
                            </xsl:call-template>
                          </p>
                        </td>
                      </xsl:if>
                      <td class="lrsource">
                        <xsl:apply-templates/>
                      </td>
                    </tr>
                    <tr>
                      <td class="lrcible">
                        <xsl:apply-templates select="$lrcibles[$seq]"/>
                      </td>
                    </tr>
                  </xsl:for-each>
                </table>
              </div>
              <xsl:if test="$arret1 &lt; $nbElems">
                <div class="{$divClass}">
                  <table class="{$tableClass}">
                    <xsl:for-each select="$lrsources[ (position() &gt; $arret1) and (position() &lt;= $nbElems) ]">
                      <xsl:variable name="seq" select="position()"/>
                      <tr>
                        <xsl:if test="$nos">
                          <td class="lrno" rowspan="2">
                            <p>
                              <xsl:call-template name="syntaxe_texte_affichage">
                                <xsl:with-param name="texte" select="$nos[$arret1 + $seq]"/>
                              </xsl:call-template>
                            </p>
                          </td>
                        </xsl:if>
                        <td class="lrsource">
                          <xsl:apply-templates/>
                        </td>
                      </tr>
                      <tr>
                        <td class="lrcible">
                          <xsl:apply-templates select="$lrcibles[$arret1 + $seq]"/>
                        </td>
                      </tr>
                    </xsl:for-each>
                  </table>
                </div>
              </xsl:if>
            </xsl:otherwise>
          </xsl:choose>
        </div>
      </xsl:when>
      <xsl:otherwise>
        <!-- listerelation colonne unique -->
        <table class="{$tableClass}">
          <xsl:if test="lrsourcee or lrciblee">
            <tr>
              <xsl:if test="$numeration != '' ">
                <td/>
              </xsl:if>
              <xsl:for-each select="lrsourcee">
                <th>
                  <xsl:apply-templates/>
                </th>
              </xsl:for-each>
              <xsl:for-each select="lrciblee">
                <th>
                  <xsl:apply-templates/>
                </th>
              </xsl:for-each>
            </tr>
          </xsl:if>
          <xsl:choose>
            <xsl:when test="$type &lt; 4">
              <!-- listerelation colonne unique type 1, 2 ou 3 -->
              <xsl:choose>
                <!-- nouveau cas -->
                <xsl:when test="elemrelation">
                  <xsl:for-each select="elemrelation">
                    <xsl:variable name="seq" select="position()"/>
                    <tr>
                      <xsl:if test="$numeration">
                        <td class="numerotation">
                          <p>
                            <xsl:choose>
                              <xsl:when test="$numeration ='decimal'">
                                <xsl:number value="$seq" format="1."/>
                              </xsl:when>
                              <xsl:when test="$numeration ='lettremaj'">
                                <xsl:number value="$seq" format="A."/>
                              </xsl:when>
                              <xsl:when test="$numeration ='lettremin'">
                                <xsl:number value="$seq" format="a."/>
                              </xsl:when>
                              <xsl:when test="$numeration ='romainmaj'">
                                <xsl:number value="$seq" format="I."/>
                              </xsl:when>
                              <xsl:when test="$numeration ='romainmin'">
                                <xsl:number value="$seq" format="i."/>
                              </xsl:when>
                            </xsl:choose>
                          </p>
                        </td>
                      </xsl:if>
                      <xsl:if test="$nos">
                        <td class="lrno">
                          <p>
                            <xsl:call-template name="syntaxe_texte_affichage">
                              <xsl:with-param name="texte" select="$nos[$seq]"/>
                            </xsl:call-template>
                          </p>
                        </td>
                      </xsl:if>
                      <xsl:for-each select="lrsource">
                        <td class="lrsource">
                          <xsl:apply-templates/>
                        </td>
                        <xsl:if test="$symbole ">
                          <td class="centre_symbole">
                            <span>
                              <xsl:value-of select="$symbole"/>
                            </span>
                          </td>
                        </xsl:if>
                      </xsl:for-each>
                      <xsl:for-each select="lrcible">
                        <td class="lrcible">
                          <xsl:apply-templates/>
                        </td>
                      </xsl:for-each>
                    </tr>
                  </xsl:for-each>
                </xsl:when>
                <xsl:otherwise>
                  <!-- ancien cas -->
                  <xsl:for-each select="$lrsources">
                    <xsl:variable name="seq" select="position()"/>
                    <tr>
                      <xsl:if test="$nos">
                        <td class="lrno">
                          <p>
                            <xsl:call-template name="syntaxe_texte_affichage">
                              <xsl:with-param name="texte" select="$nos[$seq]"/>
                            </xsl:call-template>
                          </p>
                        </td>
                      </xsl:if>
                      <td class="lrsource">
                        <xsl:apply-templates/>
                      </td>
                      <xsl:if test="$symbole ">
                        <td class="centre_symbole">
                          <span>
                            <xsl:value-of select="$symbole"/>
                          </span>
                        </td>
                      </xsl:if>
                      <td class="lrcible">
                        <xsl:apply-templates select="$lrcibles[$seq]"/>
                      </td>
                    </tr>
                  </xsl:for-each>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
              <!-- listerelation colonne unique type 4, 5 ou 6 -->
              <xsl:choose>
                <xsl:when test="elemrelation">
                  <xsl:for-each select="elemrelation">
                    <xsl:variable name="seq" select="position()"/>
                    <xsl:if test="$nos">
                      <tr>
                        <td class="lrno">
                          <p>
                            <xsl:call-template name="syntaxe_texte_affichage">
                              <xsl:with-param name="texte" select="$nos[$seq]"/>
                            </xsl:call-template>
                          </p>
                        </td>
                      </tr>
                    </xsl:if>
                    <xsl:for-each select="lrsource">
                      <tr>
                        <td class="lrsource">
                          <xsl:apply-templates/>
                        </td>
                      </tr>
                    </xsl:for-each>
                    <xsl:for-each select="lrcible">
                      <tr>
                        <td class="lrcible">
                          <xsl:apply-templates/>
                        </td>
                      </tr>
                    </xsl:for-each>
                  </xsl:for-each>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:for-each select="$lrsources">
                    <xsl:variable name="seq" select="position()"/>
                    <tr>
                      <xsl:if test="$nos">
                        <td class="lrno" rowspan="2">
                          <p>
                            <xsl:call-template name="syntaxe_texte_affichage">
                              <xsl:with-param name="texte" select="$nos[$seq]"/>
                            </xsl:call-template>
                          </p>
                        </td>
                      </xsl:if>
                      <td class="lrsource">
                        <xsl:apply-templates/>
                      </td>
                    </tr>
                    <tr>
                      <td class="lrcible">
                        <xsl:apply-templates select="$lrcibles[$seq]"/>
                      </td>
                    </tr>
                  </xsl:for-each>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:otherwise>
          </xsl:choose>
        </table>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- sources -->
  <xsl:template match="source">
    <xsl:if test="text() or node()">
      <p class="source">
        <xsl:apply-templates/>
      </p>
    </xsl:if>
  </xsl:template>

  <!-- tables -->
  <xsl:template match="tabtexte">
    <xsl:variable name="valeurID" select="@id"/>
    <xsl:variable name="type" select="@type"/>
    <xsl:element name="table">
      <xsl:attribute name="id">
        <xsl:value-of select="$valeurID"/>
      </xsl:attribute>
      <xsl:attribute name="lang">
        <xsl:value-of select="@lang"/>
      </xsl:attribute>
      <xsl:attribute name="class">
        <xsl:value-of select="concat( 'tabtexte type', $type )"/>
      </xsl:attribute>
      <xsl:apply-templates/>
    </xsl:element>
  </xsl:template>
  <xsl:template name="tradAttr">
    <xsl:param name="noeudTab"/>
    <xsl:variable name="id" select="$noeudTab/@id"/>
    <xsl:variable name="identete" select="$noeudTab/@identete"/>
    <xsl:variable name="nbcol" select="$noeudTab/@nbcol"/>
    <xsl:variable name="nbligne" select="$noeudTab/@nbligne"/>
    <xsl:variable name="portee" select="$noeudTab/@portee"/>
    <xsl:variable name="alignh" select="$noeudTab/@alignh"/>
    <xsl:variable name="carac" select="$noeudTab/@carac"/>
    <xsl:variable name="alignv" select="$noeudTab/@alignv"/>
    <xsl:if test="$id">
      <xsl:attribute name="id">
        <xsl:value-of select="$id"/>
      </xsl:attribute>
    </xsl:if>
    <xsl:if test="$identete">
      <xsl:attribute name="headers">
        <xsl:value-of select="$identete"/>
      </xsl:attribute>
    </xsl:if>
    <xsl:if test="$nbcol">
      <xsl:choose>
        <xsl:when test="$noeudTab/self::tabgrcol">
          <xsl:attribute name="colspan">
            <xsl:value-of select="$nbcol"/>
          </xsl:attribute>
        </xsl:when>
        <xsl:otherwise>
          <xsl:attribute name="colspan">
            <xsl:value-of select="$nbcol"/>
          </xsl:attribute>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
    <xsl:if test="$nbligne">
      <xsl:attribute name="rowspan">
        <xsl:value-of select="$nbligne"/>
      </xsl:attribute>
    </xsl:if>
    <xsl:if test="$portee">
      <xsl:choose>
        <xsl:when test="$portee = 'ligne'">
          <xsl:attribute name="scope">
            <xsl:text>row</xsl:text>
          </xsl:attribute>
        </xsl:when>
        <xsl:when test="$portee = 'colonne'">
          <xsl:attribute name="scope">
            <xsl:text>col</xsl:text>
          </xsl:attribute>
        </xsl:when>
        <xsl:when test="$portee = 'grligne'">
          <xsl:attribute name="scope">
            <xsl:text>rowgroup</xsl:text>
          </xsl:attribute>
        </xsl:when>
        <xsl:when test="$portee = 'grcolonne'">
          <xsl:attribute name="scope">
            <xsl:text>colgroup</xsl:text>
          </xsl:attribute>
        </xsl:when>
      </xsl:choose>
    </xsl:if>
    <xsl:if test="$alignh">
      <xsl:choose>
        <xsl:when test="$alignh = 'gauche'">
          <xsl:attribute name="style">
            <xsl:text>text-align: left;</xsl:text>
          </xsl:attribute>
        </xsl:when>
        <xsl:when test="$alignh = 'centre'">
          <xsl:attribute name="style">
            <xsl:text>text-align: center;</xsl:text>
          </xsl:attribute>
        </xsl:when>
        <xsl:when test="$alignh = 'droite'">
          <xsl:attribute name="style">
            <xsl:text>text-align: right;</xsl:text>
          </xsl:attribute>
        </xsl:when>
        <xsl:when test="$alignh = 'justifie'">
          <xsl:attribute name="style">
            <xsl:text>text-align: justify;</xsl:text>
          </xsl:attribute>
        </xsl:when>
        <xsl:when test="$alignh = 'carac'">
          <xsl:attribute name="style">
            <xsl:text>char</xsl:text>
          </xsl:attribute>
        </xsl:when>
      </xsl:choose>
    </xsl:if>
    <xsl:if test="$carac">
      <xsl:attribute name="char">
        <xsl:value-of select="$carac"/>
      </xsl:attribute>
    </xsl:if>
    <xsl:if test="$alignv">
      <xsl:choose>
        <xsl:when test="$alignv = 'haut'">
          <xsl:attribute name="style">
            <xsl:text>vertical-align: top;</xsl:text>
          </xsl:attribute>
        </xsl:when>
        <xsl:when test="$alignv = 'centre'">
          <xsl:attribute name="style">
            <xsl:text>vertical-align: middle;</xsl:text>
          </xsl:attribute>
        </xsl:when>
        <xsl:when test="$alignv = 'bas'">
          <xsl:attribute name="style">
            <xsl:text>vertical-align: bottom;</xsl:text>
          </xsl:attribute>
        </xsl:when>
        <xsl:when test="$alignv = 'lignebase'">
          <xsl:attribute name="style">
            <xsl:text>vertical-align: baseline;</xsl:text>
          </xsl:attribute>
        </xsl:when>
      </xsl:choose>
    </xsl:if>
  </xsl:template>
  <xsl:template match="tabcol">
    <xsl:element name="col">
      <xsl:call-template name="tradAttr">
        <xsl:with-param name="noeudTab" select="."/>
      </xsl:call-template>
    </xsl:element>
  </xsl:template>
  <xsl:template match="tabgrcol">
    <xsl:element name="colgroup">
      <xsl:call-template name="tradAttr">
        <xsl:with-param name="noeudTab" select="."/>
      </xsl:call-template>
      <xsl:apply-templates/>
      <!-- tabcol* -->
    </xsl:element>
  </xsl:template>
  <xsl:template match="tabentete">
    <xsl:element name="thead">
      <xsl:call-template name="tradAttr">
        <xsl:with-param name="noeudTab" select="."/>
      </xsl:call-template>
      <xsl:apply-templates/>
      <!-- tabligne+ -->
    </xsl:element>
  </xsl:template>
  <xsl:template match="tabligne">
    <xsl:element name="tr">
      <xsl:call-template name="tradAttr">
        <xsl:with-param name="noeudTab" select="."/>
      </xsl:call-template>
      <xsl:apply-templates/>
      <!-- (tabcellulee | tabcelluled)+ -->
    </xsl:element>
  </xsl:template>
  <xsl:template match="tabcelluled">
    <xsl:element name="td">
      <xsl:call-template name="tradAttr">
        <xsl:with-param name="noeudTab" select="."/>
      </xsl:call-template>
      <xsl:apply-templates/>
      <!-- blocimbrique+ -->
    </xsl:element>
  </xsl:template>
  <xsl:template match="tabcellulee">
    <xsl:element name="th">
      <xsl:call-template name="tradAttr">
        <xsl:with-param name="noeudTab" select="."/>
      </xsl:call-template>
      <xsl:apply-templates/>
      <!-- blocimbrique+ -->
    </xsl:element>
  </xsl:template>
  <xsl:template match="tabpied">
    <xsl:element name="tfoot">
      <xsl:call-template name="tradAttr">
        <xsl:with-param name="noeudTab" select="."/>
      </xsl:call-template>
      <xsl:apply-templates/>
      <!-- tabligne+ -->
    </xsl:element>
  </xsl:template>
  <xsl:template match="tabgrligne">
    <xsl:element name="tbody">
      <xsl:call-template name="tradAttr">
        <xsl:with-param name="noeudTab" select="."/>
      </xsl:call-template>
      <xsl:apply-templates/>
      <!-- tabligne+ -->
    </xsl:element>
  </xsl:template>

  <!--*** APPPENDIX ***-->
  <xsl:template match="partiesann">
    <section class="{name()}{% if article.erudit_object.processing == 'minimal' %} col-md-8{% else %} col-xs-12{% endif %}">
      <xsl:apply-templates/>
    </section>
  </xsl:template>

  <xsl:template match="grannexe | merci | grnotebio | grnote | grbiblio">
    <section id="{name()}" class="article-section {name()}" role="complementary">
      <h2>
        <xsl:choose>
          {% if not only_summary %}
          <xsl:when test="self::grannexe">
            <xsl:apply-templates select="self::grannexe" mode="toc-heading"/>
          </xsl:when>
          <xsl:when test="self::merci">
            <xsl:apply-templates select="self::merci" mode="toc-heading"/>
          </xsl:when>
          <xsl:when test="self::grnotebio">
            <xsl:apply-templates select="self::grnotebio" mode="toc-heading"/>
          </xsl:when>
          <xsl:when test="self::grnote">
            <xsl:apply-templates select="self::grnote" mode="toc-heading"/>
          </xsl:when>
          {% endif %}
          <xsl:when test="self::grbiblio">
            <xsl:apply-templates select="self::grbiblio" mode="toc-heading"/>
          </xsl:when>
        </xsl:choose>
      </h2>
      <xsl:choose>
        <xsl:when test="self::grbiblio">
          <ol class="unstyled">
            <xsl:apply-templates select="*[not(self::titre)]"/>
          </ol>
        </xsl:when>
        {% if not only_summary %}
        <xsl:when test="self::grnote">
          <ol class="unstyled">
            <xsl:apply-templates select="*[not(self::titre)]"/>
          </ol>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates select="*[not(self::titre)]"/>
        </xsl:otherwise>
        {% endif %}
      </xsl:choose>
    </section>
  </xsl:template>

  <!-- appendices / supplements -->
  <xsl:template match="annexe">
    <div class="article-section-content" role="subsection">
      <xsl:if test="no or titre">
        <h4 class="titreann">
          <xsl:if test="titre and no">
            <xsl:apply-templates select="no"/>
            <xsl:text>. </xsl:text>
          </xsl:if>
          <xsl:if test="titre">
            <xsl:apply-templates select="titre"/>
          </xsl:if>
          <xsl:if test="no and not(titre)">
            <xsl:apply-templates select="no"/>
          </xsl:if>
        </h4>
      </xsl:if>
      <xsl:apply-templates select="section1"/>
      <xsl:apply-templates select="noteann"/>
    </div>
  </xsl:template>

  <!-- notes within appendices -->
  <xsl:template match="noteann">
    <div class="{name()}">
      <xsl:apply-templates/>
    </div>
  </xsl:template>

  <xsl:template match="noteann/no">
    <a class="renote">
      <xsl:attribute name="href">#re1
        <xsl:value-of select="../@id"/>
      </xsl:attribute>
      <xsl:attribute name="id">
        <xsl:value-of select="../@id"/>
      </xsl:attribute>
      [
      <xsl:apply-templates/>]

    </a>
  </xsl:template>

  <!-- biographical notes -->
  <xsl:template match="notebio">
    <div class="notebio">
      <xsl:apply-templates/>
    </div>
  </xsl:template>

  <xsl:template match="notebio/nompers">
    <h2 class="nompers">
      <xsl:apply-templates/>
    </h2>
  </xsl:template>

  <!-- footnotes -->
  <xsl:template match="note">
    <li class="note" id="{@id}">
      <xsl:if test="no">
        <a href="#re1{@id}" class="nonote">
          <xsl:text>[</xsl:text><xsl:apply-templates select="no"/><xsl:text>]</xsl:text>
        </a>
      </xsl:if>
      <xsl:apply-templates select="alinea" mode="numero"/>
      <xsl:apply-templates select="*[not(self::alinea)][not(self::no)]"/>
    </li>
  </xsl:template>
  <xsl:template match="alinea" mode="numero">
    <span class="alinea">
      <xsl:apply-templates/>
    </span>
  </xsl:template>
  <xsl:template match="renvoi">
    <xsl:text>&#160;</xsl:text>
    <xsl:element name="a">
      <xsl:attribute name="href">
        <xsl:text>#</xsl:text><xsl:value-of select="@idref"/>
      </xsl:attribute>
      <xsl:attribute name="id">
        <xsl:value-of select="@id"/>
      </xsl:attribute>
      <xsl:attribute name="class">
        <xsl:text>norenvoi hint--bottom hint--no-animate</xsl:text>
      </xsl:attribute>
      <xsl:attribute name="data-hint">
        <xsl:variable name="idref" select="@idref"/>
        <xsl:value-of select="substring(/article/partiesann/grnote/note[@id=$idref]/*[not(self::no)], 1, 200)"/>
        <xsl:if test="string-length(/article/partiesann/grnote/note[@id=$idref]/*[not(self::no)]) &gt; 200">
          <xsl:text>[…]</xsl:text>
        </xsl:if>
      </xsl:attribute>
      <xsl:text>[</xsl:text>
      <xsl:value-of select="normalize-space()"/>
      <xsl:text>]</xsl:text>
    </xsl:element>
  </xsl:template>

  <xsl:template match="notefig|notetabl">
    <div class="notefigtab">
      <xsl:if test="no">
        <a href="#re1{@id}" id="{@id}" class="nonote">
          <xsl:apply-templates select="no"/>
        </a>
      </xsl:if>
      <xsl:apply-templates select="*[not(self::no)]"/>
    </div>
  </xsl:template>

  <xsl:template match="tableau//notefig|tableau//notetabl|figure//notefig|figure//notetabl">
    <div class="notefigtab">
      <xsl:apply-templates/>
    </div>
  </xsl:template>

  <xsl:template match="notefig/no|notetabl/no">
    <sup class="notefigtab" id="{../@id}">
      <xsl:apply-templates/>
    </sup>
  </xsl:template>

  <!-- bibliography -->
  <xsl:template match="biblio">
    <xsl:apply-templates/>
  </xsl:template>
  <xsl:template match="divbiblio">
    <li class="divbiblio">
      <h3 class="titre"><xsl:value-of select="titre"/></h3>
      <xsl:apply-templates select="refbiblio"/>
    </li>
  </xsl:template>
  <xsl:template match="biblio/titre">
    <h5 class="{name()}">
      <xsl:apply-templates/>
    </h5>
  </xsl:template>
  <xsl:template match="refbiblio">
    <xsl:variable name="valeurNO" select="no"/>
    <li class="refbiblio"  id="{@id}" role="note">
      <xsl:choose>
        <xsl:when test="$valeurNO">
          <xsl:apply-templates select="$valeurNO"/>
          <xsl:text>. </xsl:text>
        </xsl:when>
        <xsl:otherwise></xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="node()[name() != 'idpublic' and name() != 'no']"/>
      <div class="refbiblio-links">
        <xsl:element name="a">
          <xsl:attribute name="href">
            <xsl:text>http://scholar.google.com/scholar?q=</xsl:text>
            <xsl:apply-templates select="node()[name() != 'idpublic' and name() != 'no']"/>
          </xsl:attribute>
          <xsl:attribute name="class">
            <xsl:text>refbiblio-link scholar-link</xsl:text>
          </xsl:attribute>
          <xsl:attribute name="target">
            <xsl:text>_blank</xsl:text>
          </xsl:attribute>
          <xsl:text>Google Scholar</xsl:text>
        </xsl:element>
        <xsl:apply-templates select="idpublic"/>
      </div>
    </li>
  </xsl:template>

  <!--*** LISTS OF TABLES & FIGURES ***-->
  <xsl:template match="tableau/objetmedia | figure/objetmedia" mode="liste">
    <xsl:variable name="imgSrcId" select="concat('src-', image/@id)"/>
    <xsl:variable name="imgSrc" select="$vars[@n = $imgSrcId]/@value" />
    <xsl:variable name="imgPlGrId" select="concat('plgr-', image/@id)"/>
    <xsl:variable name="imgPlGr" select="$vars[@n = $imgPlGrId]/@value" />
    <xsl:for-each select=".">
      <figure class="{name(..)}" id="li{../@id}">
        <figcaption class="notitre">
          <span class="allertexte"><a href="#{../@id}">|^</a></span>
          <xsl:apply-templates select="../no"/>
          <xsl:apply-templates select="../legende/titre | ../legende/sstitre"/>
        </figcaption>
        <a href="{{ request.get_full_path }}media/{$imgPlGr}" title="{normalize-space(../legende)}" class="lightbox">
          <img src="{{ request.get_full_path }}media/{$imgSrc}" alt="{normalize-space(../legende)}"/>
        </a>
      </figure>
    </xsl:for-each>
  </xsl:template>

  <!--*** all-purpose typographic markup ***-->
  <xsl:template match="espacev">
    <span class="espacev {@espacetype}" style="height: {@dim}; display: block;">&#x00A0;</span>
  </xsl:template>

  <xsl:template match="espaceh">
    <span class="espaceh {@espacetype}" style="padding-left: {@dim};">&#x00A0;</span>
  </xsl:template>

  <xsl:template match="marquage">
    <xsl:choose>
      <xsl:when test="@typemarq='gras'">
        <strong>
          <xsl:apply-templates/>
        </strong>
      </xsl:when>
      <xsl:when test="@typemarq='italique'">
        <em>
          <xsl:apply-templates/>
        </em>
      </xsl:when>
      <xsl:when test="@typemarq='taillep'">
        <small>
          <xsl:apply-templates/>
        </small>
      </xsl:when>
      <xsl:otherwise>
        <span class="{@typemarq}">
          <xsl:apply-templates/>
        </span>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="exposant">
    <xsl:element name="sup">
      <xsl:if test="@traitementparticulier = 'oui'">
        <xsl:attribute name="class">
          <xsl:text>{% trans "special" %}</xsl:text>
        </xsl:attribute>
      </xsl:if>
      <xsl:call-template name="syntaxe_texte_affichage">
        <xsl:with-param name="texte" select="."/>
      </xsl:call-template>
    </xsl:element>
  </xsl:template>

  <xsl:template match="indice">
    <xsl:element name="sub">
      <xsl:if test="@traitementparticulier">
        <xsl:attribute name="class">
          <xsl:text>{% trans "special" %}</xsl:text>
        </xsl:attribute>
      </xsl:if>
      <xsl:call-template name="syntaxe_texte_affichage">
        <xsl:with-param name="texte" select="."/>
      </xsl:call-template>
    </xsl:element>
  </xsl:template>

  <xsl:template match="liensimple">
    <xsl:element name="a">
      <xsl:attribute name="href">
        <xsl:value-of select="@href" xmlns:xlink="http://www.w3.org/1999/xlink" />
      </xsl:attribute>
      <xsl:attribute name="id">
        <xsl:value-of select="@id"/>
      </xsl:attribute>
      <xsl:if test="not(starts-with( @href , 'http://www.erudit.org'))">
        <xsl:attribute name="target">_blank</xsl:attribute>
      </xsl:if>
      <xsl:value-of select="."/>
    </xsl:element>
  </xsl:template>

  <!-- element_nompers_affichage -->
  <xsl:template name="element_nompers_affichage">
    <xsl:param name="nompers"/>
    <xsl:if test="$nompers[@typenompers = 'pseudonyme']">
      <xsl:text> </xsl:text>
      <xsl:text>{% trans "alias" %}</xsl:text>
      <xsl:text> </xsl:text>
    </xsl:if>
    <xsl:if test="$nompers/prefixe/node()">
      <xsl:call-template name="syntaxe_texte_affichage">
        <xsl:with-param name="texte" select="$nompers/prefixe"/>
      </xsl:call-template>
      <xsl:text>
      </xsl:text>
    </xsl:if>
    <xsl:if test="$nompers/prenom/node()">
      <xsl:call-template name="syntaxe_texte_affichage">
        <xsl:with-param name="texte" select="$nompers/prenom"/>
      </xsl:call-template>
    </xsl:if>
    <xsl:if test="$nompers/autreprenom/node()">
      <xsl:text>
      </xsl:text>
      <xsl:call-template name="syntaxe_texte_affichage">
        <xsl:with-param name="texte" select="$nompers/autreprenom"/>
      </xsl:call-template>
    </xsl:if>
    <xsl:if test="$nompers/nomfamille/node()">
      <xsl:text>
      </xsl:text>
      <xsl:call-template name="syntaxe_texte_affichage">
        <xsl:with-param name="texte" select="$nompers/nomfamille"/>
      </xsl:call-template>
    </xsl:if>
    <xsl:for-each select="$nompers/suffixe[child::node()]">
      <xsl:text>, </xsl:text>
      <xsl:call-template name="syntaxe_texte_affichage">
        <xsl:with-param name="texte" select="."/>
      </xsl:call-template>
    </xsl:for-each>
  </xsl:template>

  <!-- syntaxe_texte_affichage -->
  <xsl:template name="syntaxe_texte_affichage">
    <xsl:param name="texte" select="."/>
    <xsl:for-each select="$texte/node()">
      <xsl:choose>
        <!-- #PCDATA -->
        <xsl:when test="self::text()">
          <xsl:value-of select="."/>
        </xsl:when>
        <!-- %texte -->
        <xsl:otherwise>
          <xsl:call-template name="entite_texte_affichage">
            <xsl:with-param name="texte" select="."/>
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

  <!-- entite_texte_affichage -->
  <xsl:template name="entite_texte_affichage">
    <xsl:param name="texte" select="."/>
    <xsl:apply-templates select="$texte"/>
  </xsl:template>

  <!-- noteillustrationtype -->
  <xsl:template name="noteillustrationtype">
    <xsl:param name="noteIllustration"/>
    <xsl:variable name="valeurID" select="$noteIllustration/@id"/>
    <xsl:variable name="valeurIDREF" select="concat('re1', $valeurID)"/>
    <div class="note">
      <xsl:if test="$noteIllustration/no">
        <a class="nonote" id="{$valeurID}">
          <xsl:if test="//node()[@id = $valeurIDREF]">
            <xsl:attribute name="href">
              <xsl:value-of select="concat('#', $valeurIDREF)"/>
            </xsl:attribute>
          </xsl:if>
          <xsl:text>[</xsl:text>
          <xsl:call-template name="syntaxe_texte_affichage">
            <xsl:with-param name="texte" select="$noteIllustration/no"/>
          </xsl:call-template>
          <xsl:text>]</xsl:text>
        </a>
      </xsl:if>
      <xsl:for-each select="$noteIllustration/node()[name() != '' and name() != 'no']">
        <xsl:apply-templates select="."/>
      </xsl:for-each>
    </div>
  </xsl:template>

</xsl:stylesheet>

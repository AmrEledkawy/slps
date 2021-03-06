<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:bgf="http://planet-sl.org/bgf" xmlns:ldf="http://planet-sl.org/ldf" xmlns:ldx="http://planet-sl.org/ldx" xmlns:mml="http://www.w3.org/1998/Math/MathML" xmlns:xhtml="http://www.w3.org/1999/xhtml" version="1.0">
	<xsl:import href="bgf2bnf.xslt"/>
	<xsl:import href="mathml2tex.xslt"/>
	<xsl:output method="text" encoding="UTF-8" omit-xml-declaration="yes"/>
	<xsl:template match="/ldf:document">
		<xsl:text>
\documentclass{article}
\setcounter{secnumdepth}{2}
\setcounter{tocdepth}{2}
\usepackage{listings}
\usepackage{graphicx}
\usepackage{color}
\lstdefinelanguage{pp}{%
  numbers=none,
  literate={EPSILON}{{$\varepsilon$}}1 %{STRING}{{$\lambda$}}1
  {*}{{$^\star$}}1 {+}{{$^+$}}1 {?}{{$?$}}1 {&lt;}{{$\langle$}}1 {&gt;}{{$\rangle$}}1,
  keywordstyle=\normalfont\bfseries,
 morekeywords={unfold,fold,inline,extract,abridge,detour,unchain,chain,
 massage,distribute,factor,deyaccify,yaccify,eliminate,introduce,import,vertical,horizontal,rename,
 renameL,renameN,renameS,renameT,rassoc,lassoc,
 add,addV,addH,appear,widen,upgrade,unite,
 remove,removeV,removeH,disappear,narrow,downgrade,
 abstractize,concretize,permute,
 define,undefine,redefine,inject,project,replace,
 designate,unlabel,deanonymize,anonymize,dump,reroot,in},
  columns=fullflexible,
  basicstyle=\tt,
}
\newcommand{\subsubsubsection}[1]{\paragraph{#1}}
\newcommand{\subsubsubsubsection}[1]{\subparagraph{#1}}
\makeatletter\newenvironment{graybox}{%
   \begin{lrbox}{\@tempboxa}\begin{minipage}{0.9\columnwidth}}{\end{minipage}\end{lrbox}%
   \colorbox[gray]{0.9}{\usebox{\@tempboxa}}
}\makeatother
\usepackage[unicode,bookmarks=false,pdfstartview={FitH},%
            colorlinks,linkcolor=blue,urlcolor=blue,citecolor=blue,%
            pdfauthor={LDF2TEX},backref=page,%
            pdftitle={</xsl:text>
		<xsl:value-of select="titlePage/topic"/>
		<xsl:text>}]{hyperref}
\begin{document}
    </xsl:text>
<!-- title -->
		<xsl:text>\title{</xsl:text>
		<xsl:value-of select="titlePage/topic"/>
<!-- version or edition -->
		<xsl:if test="titlePage/version">
			<xsl:text> v.</xsl:text>
			<xsl:value-of select="titlePage/version"/>
		</xsl:if>
		<xsl:if test="titlePage/edition">
			<xsl:text> </xsl:text>
			<xsl:value-of select="titlePage/edition"/>
			<xsl:text>ed</xsl:text>
		</xsl:if>
		<xsl:text>}</xsl:text>
<!-- body/number or author -->
		<xsl:text>\author{</xsl:text>
		<xsl:choose>
			<xsl:when test="titlePage/body">
				<xsl:call-template name="uppercase">
					<xsl:with-param name="string" select="titlePage/body"/>
				</xsl:call-template>
				<xsl:value-of select="titlePage/number"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="titlePage/author"/>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:text>}</xsl:text>
<!-- status -->
		<xsl:if test="titlePage/status != 'unknown'">
			<xsl:text>\institute{</xsl:text>
			<xsl:value-of select="titlePage/status"/>
			<xsl:text>}</xsl:text>
		</xsl:if>
<!-- date -->
		<xsl:text>\date{</xsl:text>
		<xsl:value-of select="titlePage/date"/>
		<xsl:text>}</xsl:text>
<!-- titlePage done -->
		<xsl:text>\maketitle</xsl:text>
<!-- placeholder: not completely implemented -->
		<xsl:apply-templates select="placeholder"/>
		<xsl:text>
		%% START_CONTENT
	  </xsl:text>
<!-- frontMatter -->
		<xsl:for-each select="frontMatter/*">
			<xsl:call-template name="sectionize">
				<xsl:with-param name="target" select="."/>
			</xsl:call-template>
			<xsl:call-template name="process-SimpleSection">
				<xsl:with-param name="section" select="."/>
			</xsl:call-template>
		</xsl:for-each>
<!-- lists -->
		<xsl:for-each select="lists/*">
			<xsl:call-template name="process-ListOfTerms">
				<xsl:with-param name="list" select="."/>
			</xsl:call-template>
		</xsl:for-each>
<!-- lexicalPart -->
		<xsl:for-each select="lexicalPart/*">
			<xsl:call-template name="sectionize">
				<xsl:with-param name="target" select="."/>
			</xsl:call-template>
			<xsl:call-template name="process-SimpleSection">
				<xsl:with-param name="section" select="."/>
			</xsl:call-template>
		</xsl:for-each>
		<xsl:text>
		%% START_CORE
	</xsl:text>
		<xsl:choose>
			<xsl:when test="count(part) = 1">
				<xsl:apply-templates select="part/core"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:for-each select="part">
					<xsl:call-template name="treatPart">
						<xsl:with-param name="part" select="."/>
					</xsl:call-template>
				</xsl:for-each>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:for-each select="backMatter/*">
			<xsl:call-template name="sectionize">
				<xsl:with-param name="target" select="."/>
			</xsl:call-template>
			<xsl:call-template name="process-SimpleSection">
				<xsl:with-param name="section" select="."/>
			</xsl:call-template>
		</xsl:for-each>
		<xsl:text>\appendix</xsl:text>
		<xsl:apply-templates select="annex"/>
		<xsl:text>\end{document}	%% END_CONTENT</xsl:text>
	</xsl:template>
	<xsl:template match="list">
		<xsl:text>\begin{itemize}</xsl:text>
		<xsl:for-each select="item">
			<xsl:text>\item </xsl:text>
			<xsl:call-template name="process-mixed">
				<xsl:with-param name="content" select="."/>
			</xsl:call-template>
		</xsl:for-each>
		<xsl:text>\end{itemize}</xsl:text>
	</xsl:template>
	<xsl:template name="process-ListOfTerms">
		<xsl:param name="list"/>
		<xsl:text>\section{</xsl:text>
		<xsl:choose>
			<xsl:when test="$list/title">
				<xsl:value-of select="$list/title"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>List of </xsl:text>
				<xsl:value-of select="local-name($list)"/>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:text>}</xsl:text>
		<xsl:text>\begin{description}</xsl:text>
		<xsl:for-each select="$list/term">
			<xsl:text>\item[</xsl:text>
			<xsl:call-template name="capitaliseString">
				<xsl:with-param name="string" select="name"/>
			</xsl:call-template>
			<xsl:text>] </xsl:text>
			<xsl:call-template name="process-text">
				<xsl:with-param name="text" select="definition"/>
			</xsl:call-template>
		</xsl:for-each>
		<xsl:text>\end{description}</xsl:text>
	</xsl:template>
	<xsl:template name="process-mixed">
		<xsl:param name="content"/>
		<xsl:for-each select="$content/node()">
			<xsl:choose>
				<xsl:when test="local-name() = 'keyword'">
					<xsl:text>\textbf{</xsl:text>
					<xsl:value-of select="."/>
					<xsl:text>}</xsl:text>
				</xsl:when>
				<xsl:when test="local-name() = 'link'">
<!-- \ref{} ??? -->
					<xsl:text>\textbf{</xsl:text>
					<xsl:value-of select="text"/>
					<xsl:text>}</xsl:text>
				</xsl:when>
				<xsl:when test="local-name() = 'formula'">
					<xsl:text>$</xsl:text>
					<xsl:apply-templates select="mml:math/*"/>
					<xsl:text>$</xsl:text>
				</xsl:when>
<!--
              <xsl:when test="namespace-uri() = 'http://planet-sl.org/ldf'">
                <xsl:apply-templates select="."/>
              </xsl:when>-->
				<xsl:otherwise>
					<xsl:copy-of select="."/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:for-each>
	</xsl:template>
	<xsl:template name="process-text">
		<xsl:param name="text"/>
		<xsl:for-each select="$text/node()">
			<xsl:choose>
				<xsl:when test="local-name() = 'title'"/>
				<xsl:when test="local-name() = 'author'"/>
				<xsl:when test="local-name() = 'empty'"/>
				<xsl:when test="local-name() = 'text'">
					<xsl:call-template name="process-mixed">
						<xsl:with-param name="content" select="."/>
					</xsl:call-template>
				</xsl:when>
				<xsl:when test="local-name() = 'list'">
					<xsl:apply-templates select="."/>
				</xsl:when>
				<xsl:when test="local-name() = 'formula'">
					<xsl:text>$</xsl:text>
					<xsl:if test="local-name($text) != 'cell'">
						<xsl:text>$</xsl:text>
					</xsl:if>
					<xsl:apply-templates select="mml:math/*"/>
<!--<xsl:value-of select="."/>-->
					<xsl:text>$</xsl:text>
					<xsl:if test="local-name($text) != 'cell'">
						<xsl:text>$</xsl:text>
					</xsl:if>
				</xsl:when>
				<xsl:when test="local-name() = 'production'">
					<xsl:text>
			\protect\mbox{}\protect
			
			\begin{graybox}
	        \begin{lstlisting}[language=pp]
</xsl:text>
					<xsl:apply-templates select="."/>
					<xsl:text>\end{lstlisting}\end{graybox}
	
	      \noindent </xsl:text>
				</xsl:when>
				<xsl:otherwise>
					<xsl:apply-templates select="."/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:for-each>
	</xsl:template>
	<xsl:template name="sectionize">
		<xsl:param name="target"/>
		<xsl:text>\section{</xsl:text>
		<xsl:choose>
			<xsl:when test="$target/title">
				<xsl:value-of select="$target/title"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:choose>
<!-- can be replaced with a unified CamelCase2Whitespace -->
					<xsl:when test="local-name() = 'lineContinuations'">
						<xsl:text>Line continuations</xsl:text>
					</xsl:when>
					<xsl:when test="local-name() = 'designGoals'">
						<xsl:text>Design goals</xsl:text>
					</xsl:when>
					<xsl:when test="local-name() = 'normativeReferences'">
						<xsl:text>Normative references</xsl:text>
					</xsl:when>
					<xsl:when test="local-name() = 'documentStructure'">
						<xsl:text>Document structure</xsl:text>
					</xsl:when>
					<xsl:when test="local-name() = 'whatsnew'">
						<xsl:text>What's new</xsl:text>
					</xsl:when>
					<xsl:when test="local-name() = 'languageOverview'">
						<xsl:text>Language overview</xsl:text>
					</xsl:when>
<!-- end of CamelCase2Whitespace -->
					<xsl:otherwise>
						<xsl:call-template name="capitaliseLocalName">
							<xsl:with-param name="section" select="$target"/>
						</xsl:call-template>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:text>}\label{</xsl:text>
		<xsl:choose>
			<xsl:when test="@id">
				<xsl:value-of select="@id"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="local-name()"/>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:text>}</xsl:text>
	</xsl:template>
	<xsl:template name="treatPart">
		<xsl:param name="part"/>
		<xsl:text>\part{</xsl:text>
<!-- text -->
		<xsl:if test="$part/title">
			<xsl:value-of select="$part/title"/>
		</xsl:if>
		<xsl:text>}</xsl:text>
<!-- anchor -->
		<xsl:text>\label{</xsl:text>
		<xsl:choose>
			<xsl:when test="$part/@id">
				<xsl:value-of select="$part/@id"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="local-name($part)"/>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:text>}</xsl:text>
		<xsl:apply-templates select="$part/*"/>
	</xsl:template>
	<xsl:template name="subsectionize">
		<xsl:param name="target"/>
		<xsl:param name="level"/>
		<xsl:text>\sub</xsl:text>
		<xsl:value-of select="$level"/>
		<xsl:text>section{</xsl:text>
		<xsl:choose>
			<xsl:when test="$target/title">
				<xsl:value-of select="$target/title"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:call-template name="capitaliseLocalName">
					<xsl:with-param name="section" select="$target"/>
				</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:text>}</xsl:text>
		<xsl:if test="@id">
			<xsl:text>\label{</xsl:text>
			<xsl:value-of select="@id"/>
			<xsl:text>}</xsl:text>
		</xsl:if>
	</xsl:template>
	<xsl:template name="process-SimpleSection">
		<xsl:param name="section"/>
		<xsl:for-each select="$section/*">
			<xsl:choose>
				<xsl:when test="local-name() = 'title'"/>
				<xsl:when test="local-name() = 'author'"/>
				<xsl:when test="local-name() = 'production'">
					<xsl:text>
			\protect\mbox{}\protect
			
			\begin{graybox}
	        \begin{lstlisting}[language=pp]
</xsl:text>
					<xsl:apply-templates select="."/>
					<xsl:text>\end{lstlisting}\end{graybox}
	
	      \noindent </xsl:text>
				</xsl:when>
				<xsl:otherwise>
					<xsl:call-template name="process-text">
						<xsl:with-param name="text" select="."/>
					</xsl:call-template>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:for-each>
<!--<xsl:if test="$section/@id">
      <xsl:text>\label{</xsl:text>
      <xsl:value-of select="$section/@id"/>
      <xsl:text>}</xsl:text>
    </xsl:if>-->
	</xsl:template>
	<xsl:template name="process-StructuredSection">
		<xsl:param name="section"/>
		<xsl:param name="level"/>
		<xsl:for-each select="$section/*">
			<xsl:choose>
				<xsl:when test="local-name() = 'subtopic'">
					<xsl:call-template name="subsectionize">
						<xsl:with-param name="target" select="."/>
						<xsl:with-param name="level">
							<xsl:value-of select="$level"/>
						</xsl:with-param>
					</xsl:call-template>
					<xsl:call-template name="process-StructuredSection">
						<xsl:with-param name="section" select="."/>
						<xsl:with-param name="level">
							<xsl:text>sub</xsl:text>
							<xsl:value-of select="$level"/>
						</xsl:with-param>
					</xsl:call-template>
				</xsl:when>
				<xsl:when test="local-name() = 'author'"/>
				<xsl:when test="local-name() = 'title'"/>
				<xsl:when test="local-name() = 'placeholder'">
					<xsl:apply-templates select="."/>
				</xsl:when>
				<xsl:when test="local-name() = 'synopsis'">
<!-- inline -->
					<xsl:call-template name="process-SimpleSection">
						<xsl:with-param name="section" select="."/>
					</xsl:call-template>
				</xsl:when>
				<xsl:otherwise>
					<xsl:call-template name="subsectionize">
						<xsl:with-param name="target" select="."/>
						<xsl:with-param name="level">
							<xsl:value-of select="$level"/>
						</xsl:with-param>
					</xsl:call-template>
					<xsl:call-template name="process-SimpleSection">
						<xsl:with-param name="section" select="."/>
					</xsl:call-template>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:for-each>
<!--<xsl:if test="$section/@id">
      <xsl:text>\label{</xsl:text>
      <xsl:value-of select="$section/@id"/>
      <xsl:text>}</xsl:text>
    </xsl:if>-->
	</xsl:template>
	<xsl:template match="core|annex">
		<xsl:call-template name="sectionize">
			<xsl:with-param name="target" select="."/>
		</xsl:call-template>
		<xsl:call-template name="process-StructuredSection">
			<xsl:with-param name="section" select="."/>
		</xsl:call-template>
	</xsl:template>
	<xsl:template name="capitaliseLocalName">
		<xsl:param name="section"/>
		<xsl:call-template name="capitaliseString">
			<xsl:with-param name="string" select="local-name($section)"/>
		</xsl:call-template>
	</xsl:template>
	<xsl:template name="capitaliseString">
		<xsl:param name="string"/>
		<xsl:value-of select="concat(translate(substring($string,1,1), 'abcdefghijklmnopqrstuvwxyz','ABCDEFGHIJKLMNOPQRSTUVWXYZ'), substring($string,2))"/>
	</xsl:template>
	<xsl:template name="uppercase">
		<xsl:param name="string"/>
		<xsl:value-of select="translate($string, 'abcdefghijklmnopqrstuvwxyz','ABCDEFGHIJKLMNOPQRSTUVWXYZ')"/>
	</xsl:template>
	<xsl:template match="sample">
		<xsl:text>
		\protect\mbox{}\protect
		
		\begin{graybox}
	    \begin{lstlisting}[language=pp]
</xsl:text>
		<xsl:value-of select="."/>
		<xsl:text>\end{lstlisting}\end{graybox}
	
	      \noindent </xsl:text>
	</xsl:template>
	<xsl:template match="code">
		<xsl:text>\texttt{</xsl:text>
		<xsl:value-of select="."/>
		<xsl:text>}</xsl:text>
	</xsl:template>
<!--
	\begin{figure}[t!]
	\begin{center}
	\includegraphics[width=0.85\textwidth]{convtree_jls_s.pdf}
	\end{center}
	\icaption{Convergence tree for the JLS grammars.}
	\label{F:jls-less}
	\end{figure}
	
-->
	<xsl:template match="figure">
		<xsl:text>
	        \begin{figure}\begin{center}
</xsl:text>
		<xsl:choose>
			<xsl:when test="source[type = 'PDF']">
				<xsl:text>\includegraphics[width=0.5\textwidth]{</xsl:text>
				<xsl:value-of select="source[type = 'PDF']/localfile"/>
				<xsl:text>}</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>...don't know how to insert a figure...</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:text>\end{center}\caption</xsl:text>
		<xsl:if test="shortcaption">
			<xsl:text>[</xsl:text>
			<xsl:value-of select="shortcaption"/>
			<xsl:text>]</xsl:text>
		</xsl:if>
		<xsl:text>{</xsl:text>
		<xsl:value-of select="caption"/>
		<xsl:text>}</xsl:text>
		<xsl:if test="@id">
			<xsl:text>\label{</xsl:text>
			<xsl:value-of select="@id"/>
			<xsl:text>}</xsl:text>
		</xsl:if>
		<xsl:text>\end{figure}

	      </xsl:text>
	</xsl:template>
	<xsl:template match="table">
		<xsl:text>
\begin{center}\begin{tabular}{c|</xsl:text>
		<xsl:for-each select="./row[1]/cell[position()&gt;1]">
			<xsl:text>c</xsl:text>
		</xsl:for-each>
		<xsl:text>}</xsl:text>
		<xsl:if test="./header">
			<xsl:for-each select="./header">
				<xsl:call-template name="process-text">
					<xsl:with-param name="text" select="cell[1]"/>
				</xsl:call-template>
				<xsl:for-each select="cell[position()&gt;1]">
					<xsl:text>&amp;</xsl:text>
					<xsl:call-template name="process-text">
						<xsl:with-param name="text" select="."/>
					</xsl:call-template>
				</xsl:for-each>
				<xsl:text>\\</xsl:text>
			</xsl:for-each>
			<xsl:text>\hline</xsl:text>
		</xsl:if>
		<xsl:for-each select="./row">
			<xsl:call-template name="process-text">
				<xsl:with-param name="text" select="cell[1]"/>
			</xsl:call-template>
			<xsl:for-each select="cell[position()&gt;1]">
				<xsl:text>&amp;</xsl:text>
				<xsl:call-template name="process-text">
					<xsl:with-param name="text" select="."/>
				</xsl:call-template>
			</xsl:for-each>
			<xsl:text>\\</xsl:text>
		</xsl:for-each>
		<xsl:text>\hline\end{tabular}\end{center}

</xsl:text>
	</xsl:template>
	
	<xsl:template match="placeholder">
<!--
      <xsd:enumeration value="index"/>
      <xsd:enumeration value="listofauthors"/>
      <xsd:enumeration value="listofreferences"/>
    -->
		<xsl:choose>
			<xsl:when test=". = 'listofcontents'">
				<xsl:text>\tableofcontents</xsl:text>
			</xsl:when>
			<xsl:when test=". = 'listoftables'">
				<xsl:text>\listoftables</xsl:text>
			</xsl:when>
			<xsl:when test=". = 'fullgrammar'">
				<xsl:text>
	        \begin{lstlisting}[language=pp]
</xsl:text>
				<xsl:for-each select="//bgf:production">
					<xsl:apply-templates select="."/>
				</xsl:for-each>
				<xsl:text>\end{lstlisting}</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>(generated content placeholder)</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
</xsl:stylesheet>

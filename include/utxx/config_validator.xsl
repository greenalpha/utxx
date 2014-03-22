<?xml version="1.0" encoding="UTF-8"?>

<!--
    This file auto-generates a class derived from utxx::validator that
    implements an init() method, which populates configuration options
    from the XML specification file supplied by an app developer.

    Copyright (c) 2012 Sergey Aleynikov <saleyn@gmail.com>
    Created: 2012-01-12
-->
     
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:output indent="yes" method="text" encoding="us-ascii"/>

<xsl:param name="now"/>
<xsl:param name="user"/>
<xsl:param name="email"/>
<xsl:param name="file"/>

<xsl:variable name="smallcase" select="'abcdefghijklmnopqrstuvwxyz'"/>
<xsl:variable name="uppercase" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'"/>

<!-- Setup the basic HTML skeleton -->
<xsl:template match="/config">
    <xsl:variable name="ifdef">
        <xsl:call-template name="def-name"/>
    </xsl:variable>
    <xsl:text>//------------------------------------------------------------------------------&#10;</xsl:text>
    <xsl:if test="$file">
        <xsl:text>// </xsl:text><xsl:value-of select="$file"/><xsl:text>&#10;</xsl:text>
    </xsl:if>
<xsl:text>// This file is auto-generated by "utxx/config_validator.xsl".
//
// *** DON'T MODIFY BY HAND!!! ***
//
// Copyright (c) 2012 Serge Aleynikov &lt;saleyn@gmail.com>
</xsl:text>
    <xsl:if test="$user">
        <xsl:text>// Generated by: </xsl:text><xsl:value-of select="$user"/>
        <xsl:if test="$email">
            <xsl:text>&lt;</xsl:text>
            <xsl:value-of select="$email"/>
            <xsl:text>&gt;</xsl:text>
        </xsl:if>
        <xsl:text>&#10;</xsl:text>
    </xsl:if>
    <xsl:text>//      Created: </xsl:text>
    <xsl:value-of select="$now"/>
    <xsl:text>&#10;//------------------------------------------------------------------------------

#ifndef </xsl:text><xsl:value-of select="$ifdef"/><xsl:text>
#define </xsl:text><xsl:value-of select="$ifdef"/>

<xsl:text>&#10;&#10;#include &lt;utxx/config_validator.hpp&gt;

namespace </xsl:text>
    <xsl:value-of select="@namespace"/><xsl:text> {
    using namespace utxx;&#10;</xsl:text>

    <xsl:call-template name="print-all-constants"/>

    <xsl:text>&#10;    namespace {
        typedef config::option_map    ovec;
        typedef config::string_set    sset;
        typedef config::variant_set   vset;
    }

    struct </xsl:text>
    <xsl:value-of select="@name"/>
    <xsl:text>: public config::validator {
    private:
        </xsl:text>
        <xsl:value-of select="@name"/><xsl:text>() {}

        friend class config::validator&lt;</xsl:text>
        <xsl:value-of select="@name"/>
        <xsl:text>&gt;;

        const </xsl:text>
        <xsl:value-of select="@name"/>
        <xsl:text>&amp; init() {
            m_root = "</xsl:text><xsl:value-of select="@namespace"/>
            <xsl:text>";&#10;</xsl:text>
    <xsl:call-template name="process_options">
        <xsl:with-param name="level">0</xsl:with-param>
        <xsl:with-param name="arg">m_options</xsl:with-param>
    </xsl:call-template>
    <xsl:text>            return *this;
        }
    };
} // namespace </xsl:text><xsl:value-of select="@namespace"/>
    <xsl:text>&#10;&#10;#endif // </xsl:text>
    <xsl:value-of select="$ifdef"/><xsl:text>&#10;</xsl:text>
</xsl:template>

    <xsl:template name="process_options">
        <xsl:param name="level"/>
        <xsl:param name="arg"/>

        <xsl:variable name="ws"><xsl:call-template name="pad">
            <xsl:with-param name="n" select="$level+6"/>
        </xsl:call-template></xsl:variable>

        <xsl:variable name="ws2"><xsl:call-template name="pad">
            <xsl:with-param name="n" select="$level+1+6"/>
        </xsl:call-template></xsl:variable>

        <xsl:variable name="ws4">
            <xsl:call-template name="pad">
                <xsl:with-param name="n" select="$level+2+6"/>
            </xsl:call-template>
        </xsl:variable>

        <xsl:for-each select="option | include">
            <xsl:choose>
                <xsl:when test="self::node()[self::option]">
                    <xsl:value-of select="$ws"/><xsl:text>{&#10;</xsl:text>
                    <xsl:value-of select="$ws2"/>
                    <xsl:text>ovec l_children</xsl:text>
                    <xsl:value-of select="$level"/>
                    <xsl:text>; sset l_names; vset l_values;&#10;</xsl:text>
                    <xsl:call-template name="process_options">
                        <xsl:with-param name="level" select="$level+1"/>
                        <xsl:with-param name="arg" select="concat('l_children',$level)"/>
                    </xsl:call-template>

                    <xsl:for-each select="name">
                        <xsl:value-of select="$ws2"/><xsl:text>l_names.insert("</xsl:text>
                        <xsl:call-template name="value-to-string">
                            <xsl:with-param name="value" select="@val"/>
                            <xsl:with-param name="type" select="../@type"/>
                        </xsl:call-template>
                        <xsl:text>");&#10;</xsl:text>
                    </xsl:for-each>

                    <xsl:for-each select="value">
                        <xsl:value-of select="$ws2"/><xsl:text>l_values.insert(variant(</xsl:text>
                        <xsl:call-template name="value-to-string">
                            <xsl:with-param name="value" select="@val"/>
                            <xsl:with-param name="type" select="../@val_type"/>
                        </xsl:call-template>
                        <xsl:text>));&#10;</xsl:text>
                    </xsl:for-each>

                    <xsl:value-of select="$ws2"/>
                    <xsl:text>add_option(</xsl:text>
                    <xsl:value-of select="$arg"/>
                    <xsl:text>,&#10;</xsl:text>
                    <xsl:text> </xsl:text>
                    <xsl:value-of select="$ws4"/>
                    <xsl:text>config::option(CFG_</xsl:text>
                    <xsl:value-of select="translate(@name, $smallcase, $uppercase)"/>
                    <xsl:text>, </xsl:text>
                    <xsl:choose>
                        <xsl:when test="@type">
                            <xsl:call-template name="string-to-type">
                                <xsl:with-param name="name" select="@name"/>
                                <xsl:with-param name="kind" select="'type_of_name'"/>
                                <xsl:with-param name="type" select="@type"/>
                            </xsl:call-template>
                        </xsl:when>
                        <xsl:when test="count(option | include) > 0">config::BRANCH</xsl:when>
                        <xsl:otherwise><xsl:text>config::STRING</xsl:text></xsl:otherwise>
                    </xsl:choose>
                    <xsl:text>, </xsl:text>
                    <xsl:variable name="type">
                        <xsl:choose>
                            <xsl:when test="not(@type) and count(option | include) > 0">string</xsl:when>
                            <xsl:otherwise><xsl:value-of select="@val_type"/></xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <xsl:call-template name="string-to-type">
                        <xsl:with-param name="name" select="@name"/>
                        <xsl:with-param name="kind" select="'type_of_value'"/>
                        <xsl:with-param name="type" select="$type"/>
                    </xsl:call-template>
                    <xsl:text>,&#10;</xsl:text>
                    <xsl:value-of select="$ws4"/>
                    <xsl:text>  "</xsl:text><xsl:value-of select="@desc"/><xsl:text>", </xsl:text>
                    <xsl:choose>
                        <xsl:when test="@unique = 'true'"><xsl:text>true</xsl:text></xsl:when>
                        <xsl:when test="@unique = 'false'"><xsl:text>false</xsl:text></xsl:when>
                        <xsl:when test="not(@unique)"><xsl:text>true</xsl:text></xsl:when>
                        <xsl:otherwise>
                            <xsl:message terminate="yes">
                                <xsl:text>Invalid value of the 'unique' attribute </xsl:text>
                                <xsl:value-of select="@unique"/><xsl:text> of option </xsl:text>
                                <xsl:value-of select="@name"/>
                            </xsl:message>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:text>, </xsl:text>
                    <xsl:choose>
                        <xsl:when test="@required = 'true'"><xsl:text>true</xsl:text></xsl:when>
                        <xsl:when test="@required = 'false'"><xsl:text>false</xsl:text></xsl:when>
                        <xsl:when test="not(@required)"><xsl:text>true</xsl:text></xsl:when>
                        <xsl:otherwise>
                            <xsl:message terminate="yes">
                                <xsl:text>Invalid value of the 'required' attribute </xsl:text>
                                <xsl:value-of select="@required"/><xsl:text> of option </xsl:text>
                                <xsl:value-of select="@name"/>
                            </xsl:message>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:text>, </xsl:text>
                    <xsl:choose>
                        <xsl:when test="not($type = 'string')"><xsl:text>config::ENV_NONE</xsl:text></xsl:when>
                        <xsl:when test="@macros = 'true'"><xsl:text>config::ENV_VARS</xsl:text></xsl:when>
                        <xsl:when test="@macros = 'false'"><xsl:text>config::ENV_NONE</xsl:text></xsl:when>
                        <xsl:when test="@macros = 'env'"><xsl:text>config::ENV_VARS</xsl:text></xsl:when>
                        <xsl:when test="@macros = 'env-date'">
                            <xsl:text>config::ENV_VARS_AND_DATETIME</xsl:text>
                        </xsl:when>
                        <xsl:when test="@macros = 'env-date-utc'">
                            <xsl:text>config::ENV_VARS_AND_DATETIME_UTC</xsl:text>
                        </xsl:when>
                        <xsl:when test="not(@macros)"><xsl:text>config::ENV_NONE</xsl:text></xsl:when>
                        <xsl:otherwise>
                            <xsl:message terminate="yes">
                                <xsl:text>Invalid value of the 'macros' attribute </xsl:text>
                                <xsl:value-of select="@macros"/><xsl:text> of option </xsl:text>
                                <xsl:value-of select="@name"/>
                            </xsl:message>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:text>,&#10;</xsl:text>
                    <xsl:value-of select="$ws4"/>
                    <xsl:text>  </xsl:text>
                    <xsl:choose>
                        <xsl:when test="@default">
                            <xsl:text>variant(</xsl:text>
                            <xsl:call-template name="value-to-string">
                                <xsl:with-param name="value" select="@default"/>
                                <xsl:with-param name="type" select="@val_type"/>
                            </xsl:call-template>
                            <xsl:text>)</xsl:text>
                        </xsl:when>
                        <xsl:otherwise><xsl:text>variant()</xsl:text></xsl:otherwise>
                    </xsl:choose>
                    <xsl:text>, </xsl:text>
                    <xsl:choose>
                        <xsl:when test="(@val_type = 'int' or @val_type = 'float') and @min">
                            <xsl:text>variant(</xsl:text><xsl:value-of select="@min"/><xsl:text>)</xsl:text>
                        </xsl:when>
                        <xsl:when test="@val_type = 'string' and @min_length">
                            <xsl:text>variant(</xsl:text><xsl:value-of select="@min_length"/><xsl:text>)</xsl:text>
                        </xsl:when>
                        <xsl:when test="@min or @min_length">
                            <xsl:message terminate="yes">
                                <xsl:text>Invalid attribute </xsl:text>
                                <xsl:if test="@min"><xsl:text>'min'</xsl:text></xsl:if>
                                <xsl:if test="@min_length"><xsl:text>'min_length'</xsl:text></xsl:if>
                                <xsl:text> specified for field: </xsl:text>
                                <xsl:value-of select="@name"/>
                                <xsl:text>, value type: </xsl:text>
                                <xsl:value-of select="@val_type"/>
                            </xsl:message>
                        </xsl:when>
                        <xsl:otherwise><xsl:text>variant()</xsl:text></xsl:otherwise>
                    </xsl:choose>
                    <xsl:text>, </xsl:text>
                    <xsl:choose>
                        <xsl:when test="(@val_type = 'int' or @val_type = 'float') and @max">
                            <xsl:text>variant(</xsl:text><xsl:value-of select="@max"/><xsl:text>)</xsl:text>
                        </xsl:when>
                        <xsl:when test="@val_type = 'string' and @max_length">
                            <xsl:text>variant(</xsl:text><xsl:value-of select="@max_length"/><xsl:text>)</xsl:text>
                        </xsl:when>
                        <xsl:when test="@max or @max_length">
                            <xsl:message terminate="yes">
                                <xsl:text>Invalid attribute </xsl:text>
                                <xsl:if test="@max"><xsl:text>'max'</xsl:text></xsl:if>
                                <xsl:if test="@max_length"><xsl:text>'max_length'</xsl:text></xsl:if>
                                <xsl:text> specified for field: </xsl:text>
                                <xsl:value-of select="@name"/>
                                <xsl:text>, value type: </xsl:text>
                                <xsl:value-of select="@val_type"/>
                            </xsl:message>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:text>variant()</xsl:text>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:text>, l_names, l_values, l_children</xsl:text>
                    <xsl:value-of select="$level"/><xsl:text>));&#10;</xsl:text>
                    <xsl:value-of select="$ws"/><xsl:text>}&#10;</xsl:text>
                </xsl:when>
                <xsl:when test="self::node()[self::include]">
                    <xsl:variable name="inc" select="document(@file)"/>
                    <xsl:for-each select="$inc">
                        <xsl:call-template name="process_options">
                            <xsl:with-param name="level" select="$level"/>
                            <xsl:with-param name="arg" select="concat('l_children',$level - 1)"/>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:when>
            </xsl:choose>
        </xsl:for-each>
    </xsl:template>

    <xsl:template name="value-to-string">
        <xsl:param name="value"/>
        <xsl:param name="type"/>
        <xsl:choose>
            <xsl:when test="$type = 'string'">
                <xsl:text>"</xsl:text>
                <xsl:value-of select="$value"/>
                <xsl:text>"</xsl:text>
            </xsl:when>
            <xsl:otherwise><xsl:value-of select="$value"/></xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="string-to-type">
        <xsl:param name="name"/>
        <xsl:param name="kind"/>
        <xsl:param name="type"/>
        <xsl:choose>
            <xsl:when test="$type = 'string'"><xsl:text>config::STRING</xsl:text></xsl:when>
            <xsl:when test="$type = 'int'"><xsl:text>config::INT</xsl:text></xsl:when>
            <xsl:when test="$type = 'bool'"><xsl:text>config::BOOL</xsl:text></xsl:when>
            <xsl:when test="$type = 'float'"><xsl:text>config::FLOAT</xsl:text></xsl:when>
            <xsl:when test="$type = 'anonymous'"><xsl:text>config::ANONYMOUS</xsl:text></xsl:when>
            <xsl:otherwise>
                <xsl:message terminate="yes">
                    <xsl:text>ERROR: undefined </xsl:text>
                    <xsl:value-of select="$kind"/>
                    <xsl:text> of option: </xsl:text>
                    <xsl:value-of select="$name"/>
                </xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="def-name">
        <xsl:text>_AUTOGEN_</xsl:text>
        <xsl:value-of select="translate(concat(@namespace, '_', @name), $smallcase, $uppercase)"/>
        <xsl:text>_HPP_</xsl:text>
    </xsl:template>

    <xsl:template name="pad">
        <xsl:param name="n" select="0"/>
        <xsl:param name="char" select="'  '"/>
        <xsl:if test="$n &gt; 0">
            <xsl:value-of select="$char"/>
            <xsl:call-template name="pad">
                <xsl:with-param name="n" select="number($n) - 1"/>
                <xsl:with-param name="char" select="$char"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>

    <xsl:template name="pad-right">
        <xsl:param name="value"/>
        <xsl:param name="len"/>
        <xsl:param name="char" select="' '"/>
        <xsl:value-of select="$value"/>
        <xsl:call-template name="pad">
            <xsl:with-param name="n" select="number($len) - string-length($value)"/>
            <xsl:with-param name="char" select="$char"/>
        </xsl:call-template>
    </xsl:template>

    <xsl:template name="maximum">
        <xsl:param name="values"/>
        <xsl:for-each select="$values">
            <xsl:sort select="string-length(.)" data-type="number" order="descending"/>
            <xsl:if test="position()=1"><xsl:value-of select="string-length(.)"/></xsl:if>
        </xsl:for-each>
    </xsl:template>

    <xsl:template name="print-all-constants">
        <!-- Find all include files and generate a unique list -->
        <xsl:variable name="include-files" select="*//include[not(@file = preceding::include/@file)]/@file"/>
        <!-- Print all @name constants as 'static const char CFG_<Name>[] = "<Value>";' -->
        <xsl:call-template name="print-all-option-names">
            <!-- select all nodes in current document -->
            <xsl:with-param name="node-set" select="*//@name"/>
            <!-- select unique list if include/@file nodes in current document -->
            <xsl:with-param name="files" select="$include-files"/>
        </xsl:call-template>

        <!-- Print all @val constants as 'static const char CFG_VAL_<Name>[] = "<Value>";' -->
        <xsl:call-template name="print-all-values">
            <!-- select all nodes in current document -->
            <xsl:with-param name="node-set" select="*//value/@val | *//name/@val"/>
            <!-- select unique list if include/@file nodes in current document -->
            <xsl:with-param name="files" select="$include-files"/>
        </xsl:call-template>
    </xsl:template>

    <xsl:template name="print-all-option-names">
        <xsl:param name="node-set"/>  <!-- This is node accumulator -->
        <xsl:param name="files"/>     <!-- Remaining files to be processed -->
        <xsl:if test="count($files) > 0">
            <!-- Get all @name(s) from the first file in the list -->
            <xsl:variable name="file" select="$files[position() = 1]"/>
            <xsl:variable name="doc" select="document($file)"/>
            <xsl:variable name="nodes" select="$doc//@name"/>
            <!-- Merge two node-sets and recursively collect @name(s) from remaining files -->
            <xsl:call-template name="print-all-option-names">
                <xsl:with-param name="node-set" select="$node-set | $nodes"/>
                <xsl:with-param name="files" select="$files[position() &gt; 1]"/>
            </xsl:call-template>
        </xsl:if>
        <xsl:if test="count($files) = 0">
            <!-- This is the end of recursion - all 'include' files have been processed -->
            <!-- All @name(s) have been collected in $node-set. -->
            <xsl:variable name="max-name-len">
                <xsl:call-template name="maximum">
                    <xsl:with-param name="values" select="$node-set"/>
                </xsl:call-template>
            </xsl:variable>

            <xsl:text>&#10;</xsl:text>
            <xsl:text>    //---------- Configuration Options ------------</xsl:text>
            <xsl:text>&#10;</xsl:text>

            <!-- Uniquely sort $node-set and print out each constant -->
            <xsl:for-each select="$node-set[not(self::node() = preceding::option/@name)]">
                <xsl:sort select="translate(self::node(), $smallcase, $uppercase)"/>
                <xsl:text>    static const char CFG_</xsl:text>
                <xsl:call-template name="pad-right">
                    <xsl:with-param name="len" select="$max-name-len + 3"/>
                    <xsl:with-param name="value" select="concat(translate(self::node(), $smallcase, $uppercase), '[]')"/>
                </xsl:call-template>
                <xsl:text>= "</xsl:text>
                <xsl:value-of select="self::node()"/>
                <xsl:text>";&#10;</xsl:text>
            </xsl:for-each>
            <xsl:text>&#10;</xsl:text>
        </xsl:if>
    </xsl:template>

    <!-- Key for unique @name lookup -->
    <xsl:key name="k" match="*//@name" use="self::node()"/>
    <!-- Key for unique @val lookup -->
    <xsl:key name="v" match="*//value/@val | *//name/@val" use="self::node()"/>

    <xsl:template name="print-all-values">
        <xsl:param name="node-set"/>
        <!-- This is node accumulator -->
        <xsl:param name="files"/>
        <!-- Remaining files to be processed -->
        <xsl:if test="count($files) > 0">
            <!-- Get all @name(s) from the first file in the list -->
            <xsl:variable name="file" select="$files[position() = 1]"/>
            <xsl:variable name="doc" select="document($file)"/>
            <xsl:variable name="nodes" select="$doc//name/@val | $doc//value/@val"/>
            <!-- Merge two node-sets and recursively collect @name(s) from remaining files -->
            <xsl:call-template name="print-all-values">
                <xsl:with-param name="node-set" select="$node-set | $nodes"/>
                <xsl:with-param name="files" select="$files[position() &gt; 1]"/>
            </xsl:call-template>
        </xsl:if>
        <xsl:if test="count($files) = 0">
            <!-- This is the end of recursion - all 'include' files have been processed -->
            <!-- All @val(s) have been collected in $node-set. -->
            <xsl:variable name="max-val-len">
                <xsl:call-template name="maximum">
                    <xsl:with-param name="values" select="$node-set"/>
                </xsl:call-template>
            </xsl:variable>

            <xsl:text>&#10;</xsl:text>
            <xsl:text>    //---------- Configuration Values -------------</xsl:text>
            <xsl:text>&#10;</xsl:text>

            <!-- Uniquely sort $node-set and print out each constant -->
            <xsl:for-each select="$node-set[not(self::node() = preceding::name/@val or self::node() = preceding::value/@val)]">
                <xsl:sort select="translate(self::node(), $smallcase, $uppercase)"/>
                <xsl:text>    static const char CFG_VAL_</xsl:text>
                <xsl:call-template name="pad-right">
                    <xsl:with-param name="len" select="$max-val-len + 3"/>
                    <xsl:with-param name="value" select="concat(translate(self::node(), $smallcase, $uppercase), '[]')"/>
                </xsl:call-template>
                <xsl:text>= "</xsl:text>
                <xsl:value-of select="self::node()"/>
                <xsl:text>";&#10;</xsl:text>
            </xsl:for-each>
            <xsl:text>&#10;</xsl:text>
            <!-- -->
        </xsl:if>
    </xsl:template>

<!-- This is a depricated sorting approach that worked well, but didn't process include files.
<xsl:template name="print-constants">
    <xsl:variable name="max-name-len">
        <xsl:call-template name="maximum">
            <xsl:with-param name="values" select="*//option/@name"/>
        </xsl:call-template>
    </xsl:variable>

    <xsl:variable name="max-val-len">
        <xsl:call-template name="maximum">
            <xsl:with-param name="values" select="*//name/@val | *//value/@val"/>
        </xsl:call-template>
    </xsl:variable>

    <xsl:variable name="max-len">
        <xsl:choose>
            <xsl:when test="$max-name-len+6 > $max-val-len"><xsl:value-of select="$max-name-len+6"/></xsl:when>
            <xsl:otherwise><xsl:value-of select="$max-val-len"/></xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <xsl:text>&#10;</xsl:text>
    <xsl:text>    //========== Configuration Options ============</xsl:text>
    <xsl:text>&#10;</xsl:text>

    <xsl:for-each select="(*//@name)[count(.|key('k', self::node())[1]) = 1]">
        <xsl:sort select="translate(self::node(), $smallcase, $uppercase)"/>
        <xsl:text>    static const char CFG_</xsl:text>
        <xsl:call-template name="pad-right">
            <xsl:with-param name="len" select="$max-len"/>
            <xsl:with-param name="value" select="concat(translate(self::node(), $smallcase, $uppercase), '[]')"/>
        </xsl:call-template>
        <xsl:text>= "</xsl:text>
        <xsl:value-of select="self::node()"/>
        <xsl:text>";&#10;</xsl:text>
    </xsl:for-each>

    <xsl:text>&#10;</xsl:text>
    <xsl:text>    //========== Configuration Values =============</xsl:text>
    <xsl:text>&#10;</xsl:text>

    <xsl:for-each select="(*//name/@val | *//value/@val)[count(.|key('v', self::node())[1]) = 1]">
        <xsl:sort select="translate(self::node(), $smallcase, $uppercase)"/>
        <xsl:text>    static const char CFG_VAL_</xsl:text>
        <xsl:call-template name="pad-right">
            <xsl:with-param name="len" select="$max-len - 4"/>
            <xsl:with-param name="value" select="concat(translate(self::node(), $smallcase, $uppercase), '[]')"/>
        </xsl:call-template>
        <xsl:text>= "</xsl:text>
        <xsl:value-of select="self::node()"/>
        <xsl:text>";&#10;</xsl:text>
    </xsl:for-each>
</xsl:template>
-->
    
</xsl:stylesheet>

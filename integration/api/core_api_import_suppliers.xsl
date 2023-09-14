<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xpath-default-namespace="http://protege.stanford.edu/xml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xalan="http://xml.apache.org/xslt" xmlns:pro="http://protege.stanford.edu/xml" xmlns:eas="http://www.enterprise-architecture.org/essential" xmlns:functx="http://www.functx.com" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:ess="http://www.enterprise-architecture.org/essential/errorview">
    <xsl:include href="../../common/core_utilities.xsl"/>
	<xsl:include href="../../common/core_js_functions.xsl"/>
	<xsl:output method="text" encoding="UTF-8"/>
	<xsl:param name="param1"/> 
	<xsl:variable name="allSupplier" select="/node()/simple_instance[type = 'Supplier']"/>     
    <xsl:variable name="apps"  select="/node()/simple_instance[type='Composite_Application_Provider']"></xsl:variable>
	<xsl:key name="supplier" match="/node()/simple_instance[type='Supplier']" use="name"/> 
	<xsl:variable name="supps" select="key('supplier', $apps/own_slot_value[slot_reference='ap_supplier']/value)"/>
    <xsl:key name="appsKey" match="$apps" use="own_slot_value[slot_reference='ap_supplier']/value"/> 
    <xsl:variable name="processes"  select="/node()/simple_instance[type='Physical_Process']"></xsl:variable>
    <xsl:variable name="actorSuppliers"  select="/node()/simple_instance[type='Group_Actor'][own_slot_value[slot_reference='external_to_enterprise']/value='true']"></xsl:variable>
    <xsl:key name="actortoRole" match="/node()/simple_instance[type='ACTOR_TO_ROLE_RELATION']" use="own_slot_value[slot_reference='act_to_role_from_actor']/value"/> 
    <xsl:key name="actorProcesses" match="/node()/simple_instance[type='Physical_Process']" use="own_slot_value[slot_reference='process_performed_by_actor_role']/value"/> 
    <xsl:key name="processes" match="/node()/simple_instance[type='Business_Process']" use="own_slot_value[slot_reference='implemented_by_physical_business_processes']/value"/> 
	<xsl:variable name="focusClass" select="/node()/class[name = ('Supplier')]" />
	<xsl:variable name="classSlots" select="/node()/slot[name = $focusClass/template_slot]" />
	<xsl:variable name="parentEnumClass" select="/node()/class[superclass = 'Enumeration']" />
	<xsl:variable name="subEnumClass" select="/node()/class[superclass = $parentEnumClass/name]" />
	<xsl:variable name="enumClass" select="$parentEnumClass union $subEnumClass" />
	<xsl:variable name="targetSlots" select="$classSlots/own_slot_value[slot_reference=':SLOT-VALUE-TYPE']/value[2]"/>
	<xsl:variable name="allclassSlots" select="$classSlots[own_slot_value[slot_reference=':SLOT-VALUE-TYPE']/value=$enumClass/name]"/> 
	<xsl:variable name="allEnumClass" select="$enumClass[name=$targetSlots]"/> 
		<!--
		* Copyright © 2008-2019 Enterprise Architecture Solutions Limited.
	 	* This file is part of Essential Architecture Manager, 
	 	* the Essential Architecture Meta Model and The Essential Project.
		*
		* Essential Architecture Manager is free software: you can redistribute it and/or modify
		* it under the terms of the GNU General Public License as published by
		* the Free Software Foundation, either version 3 of the License, or
		* (at your option) any later version.
		*
		* Essential Architecture Manager is distributed in the hope that it will be useful,
		* but WITHOUT ANY WARRANTY; without even the implied warranty of
		* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
		* GNU General Public License for more details.
		*
		* You should have received a copy of the GNU General Public License
		* along with Essential Architecture Manager.  If not, see <http://www.gnu.org/licenses/>.
		* 
	-->
	<!-- 03.09.2019 JP  Created	 -->
	 
	<xsl:template match="knowledge_base">
		{"suppliers":[<xsl:apply-templates select="$allSupplier" mode="getSupplier"><xsl:sort select="own_slot_value[slot_reference='name']/value" order="ascending"/></xsl:apply-templates>],
		"suppliersProcess":[<xsl:apply-templates select="$actorSuppliers" mode="actorSuppliers"><xsl:sort select="own_slot_value[slot_reference='name']/value" order="ascending"/></xsl:apply-templates>],
		"suppliersApps":[<xsl:apply-templates select="$supps" mode="supps"><xsl:sort select="own_slot_value[slot_reference='name']/value" order="ascending"/></xsl:apply-templates>],
		"filters":[<xsl:apply-templates select="$allEnumClass" mode="createFilterJSON"></xsl:apply-templates>],
		"version":"618"}
	</xsl:template>

	<xsl:template match="node()" mode="getSupplier">
			<xsl:variable name="this" select="current()"/>
		   {"id":"<xsl:value-of select="$this/name"/>","name":"<xsl:call-template name="RenderMultiLangInstanceName">
					<xsl:with-param name="theSubjectInstance" select="$this"/>
					<xsl:with-param name="isRenderAsJSString" select="true()"/>
				</xsl:call-template>",
			"className":"<xsl:value-of select="current()/type"/>",	
			"supplierActor":"<xsl:value-of select="$this/own_slot_value[slot_reference='supplier_actor']/value"/>",	
			"esg_rating":"<xsl:value-of select="$this/own_slot_value[slot_reference='esg_rating']/value"/>"}<xsl:if test="position()!=last()">,</xsl:if>
	</xsl:template>
	<xsl:template match="node()" mode="actorSuppliers">
		<xsl:variable name="thisA2r" select="key('actortoRole',current()/name)"/>
		<xsl:variable name="thisProcesses" select="key('actorProcesses',$thisA2r/name)"/>
		{"id":"<xsl:value-of select="current()/name"/>",
		"name":"<xsl:call-template name="RenderMultiLangInstanceName">
							<xsl:with-param name="theSubjectInstance" select="current()"/>
							<xsl:with-param name="isRenderAsJSString" select="true()"/>
						</xsl:call-template>",	
		"supplierActor":"<xsl:value-of select="$allSupplier[own_slot_value[slot_reference='supplier_actor']/value=current()/name]/name"/>",						
		"processes":[<xsl:for-each select="$thisProcesses">
		<xsl:variable name="thisProcess" select="key('processes',current()/name)"/>
				{"id":"<xsl:value-of select="current()/name"/>",
				"name":"<xsl:call-template name="RenderMultiLangInstanceName">
							<xsl:with-param name="theSubjectInstance" select="$thisProcess"/>
							<xsl:with-param name="isRenderAsJSString" select="true()"/>
						</xsl:call-template>",
				"physname":"<xsl:call-template name="RenderMultiLangInstanceName">
							<xsl:with-param name="theSubjectInstance" select="current()"/>
							<xsl:with-param name="isRenderAsJSString" select="true()"/>
						</xsl:call-template>"}<xsl:if test="position()!=last()">,</xsl:if>
        </xsl:for-each>]
		}<xsl:if test="position()!=last()">,</xsl:if>
	</xsl:template>
 <xsl:template match="node()" mode="supps">
{"id":"<xsl:value-of select="current()/name"/>",
"name":"<xsl:call-template name="RenderMultiLangInstanceName">
            <xsl:with-param name="theSubjectInstance" select="current()"/>
            <xsl:with-param name="isRenderAsJSString" select="true()"/>
</xsl:call-template>",<xsl:variable name="thisApps" select="key('appsKey', current()/name)"/>
"apps":[<xsl:for-each select="$thisApps">{"id":"<xsl:value-of select="current()/name"/>",
        "name":"<xsl:call-template name="RenderMultiLangInstanceName">
					<xsl:with-param name="theSubjectInstance" select="current()"/>
					<xsl:with-param name="isRenderAsJSString" select="true()"/>
				</xsl:call-template>"}<xsl:if test="position()!=last()">,</xsl:if>
</xsl:for-each>]}<xsl:if test="position()!=last()">,</xsl:if>
 </xsl:template> 
<xsl:template mode="createFilterJSON" match="node()">	
		<xsl:variable name="thisSlot" select="$classSlots[own_slot_value[slot_reference=':SLOT-VALUE-TYPE']/value=current()/name]"/> 
		<xsl:variable name="releventEnums" select="/node()/simple_instance[type = current()/name]"/> 
		{"id": "<xsl:value-of select="current()/name"/>",
		"name": "<xsl:value-of select="translate(current()/name, '_',' ')"/>",
		"valueClass": "<xsl:value-of select="current()/name"/>",
		"description": "",
		"slotName":"<xsl:value-of select="$thisSlot/name"/>",
		"isGroup": false,
		"icon": "fa-circle",
		"color":"hsla(25, 52%, 38%, 1)",
		"values": [
		<xsl:for-each select="$releventEnums"><xsl:sort select="own_slot_value[slot_reference='enumeration_sequence_number']/value" order="ascending"/>{"id":"<xsl:value-of select="eas:getSafeJSString(current()/name)"/>", "name":"<xsl:call-template name="RenderMultiLangInstanceName">
			<xsl:with-param name="theSubjectInstance" select="current()"></xsl:with-param>
			<xsl:with-param name="isForJSONAPI" select="true()"></xsl:with-param>
		</xsl:call-template>",
		"enum_name":"<xsl:call-template name="RenderMultiLangInstanceSlot">
		<xsl:with-param name="theSubjectInstance" select="current()"></xsl:with-param>
		<xsl:with-param name="displaySlot" select="'enumeration_value'"/>
		<xsl:with-param name="isForJSONAPI" select="true()"></xsl:with-param>
		</xsl:call-template>",
		"sequence":"<xsl:value-of select="own_slot_value[slot_reference='enumeration_sequence_number']/value"/>", 
		"backgroundColor":"<xsl:value-of select="eas:get_element_style_colour(current())"/>",
		"colour":"<xsl:value-of select="eas:get_element_style_textcolour(current())"/>"}<xsl:if test="position()!=last()">,</xsl:if> </xsl:for-each>]}<xsl:if test="position()!=last()">,</xsl:if>
</xsl:template> 
</xsl:stylesheet>

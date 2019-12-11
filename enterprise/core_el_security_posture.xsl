<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet version="2.0" xpath-default-namespace="http://protege.stanford.edu/xml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xalan="http://xml.apache.org/xslt" xmlns:pro="http://protege.stanford.edu/xml" xmlns:eas="http://www.enterprise-architecture.org/essential" xmlns:functx="http://www.functx.com" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:ess="http://www.enterprise-architecture.org/essential/errorview">
	<xsl:include href="../common/core_doctype.xsl"/>
	<xsl:include href="../common/core_common_head_content.xsl"/>
	<xsl:include href="../common/core_header.xsl"/>
	<xsl:include href="../common/core_footer.xsl"/>



	<xsl:output method="html"/>

	<!--
		* Copyright © 2008-2017 Enterprise Architecture Solutions Limited.
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
	<!-- 19.04.2008 JP  Migrated to new servlet reporting engine	 -->
	<!-- 06.11.2008 JWC	Migrated to XSL v2 -->
	<!-- 29.06.2010	JWC	Fixed details links to support " ' " characters in names -->
	<!-- 01.05.2011 NJW Updated to support Essential Viewer version 3-->
	<!-- 05.01.2016 NJW Updated to support Essential Viewer version 5-->


	<!-- START GENERIC CATALOGUE PARAMETERS -->
	<xsl:param name="targetReportId"/>
	<xsl:param name="targetMenuShortName"/>
	<xsl:param name="viewScopeTermIds"/>

	<!-- END GENERIC CATALOGUE PARAMETERS -->


	<!-- START GENERIC CATALOGUE SETUP VARIABES -->
	<xsl:variable name="targetReport" select="/node()/simple_instance[name = $targetReportId]"/>
	<xsl:variable name="targetMenu" select="eas:get_menu_by_shortname($targetMenuShortName)"/>
	<xsl:variable name="viewScopeTerms" select="eas:get_scoping_terms_from_string($viewScopeTermIds)"/>
	<xsl:variable name="linkClasses" select="('Technology_Product', 'Supplier')"/>
	<!-- END GENERIC CATALOGUE SETUP VARIABES -->

	<xsl:variable name="pageLabel">
		<xsl:value-of select="eas:i18n('Security Profile')"/>
	</xsl:variable>
	<xsl:variable name="techProdListByComponentCatalogue" select="/node()/simple_instance[(type = 'Report') and (own_slot_value[slot_reference = 'name']/value = 'Core: Technology Product Catalogue by Technology Component')]"/>
	<xsl:variable name="techProdListByCapCatalogue" select="/node()/simple_instance[(type = 'Report') and (own_slot_value[slot_reference = 'name']/value = 'Core: Technology Product Catalogue by Technology Capability')]"/>
	<xsl:variable name="techProdListAsTableCatalogue" select="eas:get_report_by_name('Core: Technology Product Cataloigue as Table')"/>
    <xsl:variable name="allTechProdFamilies" select="/node()/simple_instance[type = 'Technology_Product_Family']"/>
	<xsl:variable name="allTechSuppliers" select="/node()/simple_instance[type = 'Supplier']"/>
	<xsl:variable name="allTechProds" select="/node()/simple_instance[type = 'Technology_Product']"/>
	<xsl:variable name="allTechProdRoles" select="/node()/simple_instance[type = 'Technology_Product_Role'][own_slot_value[slot_reference = 'role_for_technology_provider']/value = $allTechProds/name]"/>
	<xsl:variable name="allTPUs" select="/node()/simple_instance[type = 'Technology_Provider_Usage'][own_slot_value[slot_reference = 'provider_as_role']/value = $allTechProdRoles/name]"/>

	<xsl:variable name="allTPURels" select="/node()/simple_instance[type = ':TPU-TO-TPU-RELATION'][own_slot_value[slot_reference = ':TO']/value = $allTPUs/name or own_slot_value[slot_reference = ':FROM']/value = $allTPUs/name]"/>
	<xsl:variable name="allTechProdBuildsArchs" select="/node()/simple_instance[type = 'Technology_Build_Architecture'][own_slot_value[slot_reference = 'contained_provider_architecture_relations']/value = $allTPURels/name]"/>
	<xsl:variable name="allTechProdBuilds" select="/node()/simple_instance[type = 'Technology_Product_Build'][own_slot_value[slot_reference = 'technology_provider_architecture']/value = $allTechProdBuildsArchs/name]"/>

	<xsl:variable name="allAppDeps" select="/node()/simple_instance[type = 'Application_Deployment'][own_slot_value[slot_reference = 'application_deployment_technical_arch']/value = $allTechProdBuilds/name]"/>
	<xsl:variable name="allApps" select="/node()/simple_instance[type = ('Application_Provider', 'Composite_Application_Provider')][own_slot_value[slot_reference = 'deployments_of_application_provider']/value = $allAppDeps/name]"/>
	<xsl:variable name="allAPRs" select="/node()/simple_instance[type = 'Application_Provider_Role'][own_slot_value[slot_reference = 'role_for_application_provider']/value = $allApps/name]"/>
	<xsl:variable name="allAPRstoProcs" select="/node()/simple_instance[type = 'APP_PRO_TO_PHYS_BUS_RELATION'][own_slot_value[slot_reference = 'apppro_to_physbus_from_appprorole']/value = $allAPRs/name]"/>
	<xsl:variable name="allPhysProcsBase" select="/node()/simple_instance[type = 'Physical_Process']"/>
	<xsl:variable name="allPhysProcs" select="$allPhysProcsBase[own_slot_value[slot_reference = 'phys_bp_supported_by_app_pro']/value = $allAPRstoProcs/name]"/>
	<xsl:variable name="allBusProcs" select="/node()/simple_instance[type = 'Business_Process'][own_slot_value[slot_reference = 'implemented_by_physical_business_processes']/value = $allPhysProcs/name]"/>

	<xsl:template match="knowledge_base">
		<!-- SET THE STANDARD VARIABLES THAT ARE REQUIRED FOR THE VIEW -->
		<xsl:choose>
			<xsl:when test="string-length($viewScopeTermIds) > 0">
				<xsl:call-template name="BuildPage">
					<xsl:with-param name="inScopeTechSuppliers" select="$allTechSuppliers"/>
					<!-- DOES NOT FILTER SUPPLIERS WITH TAXONOMY TERMS -->
					<xsl:with-param name="inScopeTechProds" select="$allTechProds[own_slot_value[slot_reference = 'element_classified_by']/value = $viewScopeTerms/name]"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:call-template name="BuildPage">
					<xsl:with-param name="inScopeTechSuppliers" select="$allTechSuppliers"/>
					<xsl:with-param name="inScopeTechProds" select="$allTechProds"/>
				</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="BuildPage">
		<xsl:param name="inScopeTechSuppliers"/>
		<xsl:param name="inScopeTechProds"/>
		<xsl:call-template name="docType"/>
		<html>
			<head>
				<xsl:call-template name="commonHeadContent"/>
                <xsl:call-template name="RenderModalReportContent"><xsl:with-param name="essModalClassNames" select="$linkClasses"/></xsl:call-template>
				<script type="text/javascript" src="js/handlebars-v4.1.2.js"/>
				<title>
					<xsl:value-of select="$pageLabel"/>
				</title>
				<style>
					.product {
						width: 250px;
						display: inline-block;
						font-size: 90%;
						margin-right: 10px;
					}
					
					.panel-text{
						max-height:60px;
						overflow-y: auto;
						min-height:60px 
					}
					
					.circle{
						width: 20px;
						height: 20px;
						border-radius: 50%;
						font-size: 12px;
						color: #fff;
						line-height: 20px;
						text-align: center;
						display: inline-block;
					}
					
					.circleAll{
						width: 10px;
						height: 10px;
						border-radius: 50%;
						font-size: 12px;
						color: #fff;
						line-height: 20px;
						text-align: center;
						display: inline-block;
					}
					
					.HIGH{
						background-color: #cd3232;
						color: #ffffff
					}
					
					.MEDIUM{
						background-color: #f4ad3a;
						color: #000000
					}
					
					.LOW{
						background-color: #9adda2;
						color: #000000
					}
					
					.NONE{
						background-color: #d3d3d3;
						color: #d3d3d3
					}
					
					.nistlogo{
						float: right;
						position: relative;
					}
					
					#nist-logo-img{
						height: 30px;
						margin-right: 10px;
					}
					
					#nvd-logo-img{
						height: 29px;
					}
					
					.nothing2see{
						background-color: #5eb56f;
						color: #ffffff;
						font-size: 16pt;
						border-radius: 3px}</style>
				<script>
					$(document).ready(function(){
						$('#productsSelect').select2({theme: "bootstrap"});
						$('#HMLSelect').select2({theme: "bootstrap"});
					});
				</script>
			</head>
			<body>
				<!-- ADD JAVASCRIPT FOR CONTEXT POP-UP MENUS, WHERE REQUIRED -->
				<xsl:for-each select="$linkClasses">
					<xsl:call-template name="RenderInstanceLinkJavascript">
						<xsl:with-param name="instanceClassName" select="current()"/>
						<xsl:with-param name="targetMenu" select="()"/>
					</xsl:call-template>
				</xsl:for-each>

				<!-- ADD THE PAGE HEADING -->
				<xsl:call-template name="Heading"/>

				<!--ADD THE CONTENT-->
				<a id="top"/>
				<div class="container-fluid">
					<div class="row">
						<div class="col-xs-12">
							<div class="page-header">
								<h1>
									<span class="text-primary"><xsl:value-of select="eas:i18n('View')"/>: </span>
									<span class="text-darkgrey">
										<xsl:value-of select="$pageLabel"/>
									</span>
									<div class="nistlogo">
										<img id="nist-logo-img" src="images/nist.png"/>
										<img id="nvd-logo-img" src="images/NVD-logo.png"/>
									</div>
								</h1>
							</div>
						</div>
					</div>
					<div class="row">
						<div id="sectionCatalogue">
							<div class="col-xs-8">
								<span class="strong right-5">Vendor:</span>
								<select id="productsSelect" onchange="getSupplier(this.value)" style="width: 300px;">
									<option value="all" selected="True">.All</option>
								</select>
								<span class="strong right-5 left-15">Severity:</span>
								<select id="HMLSelect" style="width: 300px;">
									<option value="all" selected="True">All</option>
									<option value="HIGH">High</option>
									<option value="MEDIUM">Medium</option>
									<option value="LOW">Low</option>
								</select>
							</div>
							<div class="nothing2see col-xs-4" id="nothingToSee"/> 
							<div class="col-xs-12 top-15">
								<div id="prodCards"/>
							</div>
						</div>
					</div>
				</div>

				<!-- Modal -->
				<div class="modal" tabindex="-1" role="dialog" id="appModal">
					<div class="modal-dialog modal-lg" role="document">
						<div class="modal-content">
							<div class="modal-header">
								<h3 class="modal-title">Potential Impacts</h3>
							</div>
							<div class="modal-body">
								<div id="modalCards"/>

							</div>
							<div class="modal-footer">
								<button type="button" class="btn btn-secondary" data-dismiss="modal">Close</button>
							</div>
						</div>
					</div>
				</div>


				<!-- ADD THE PAGE FOOTER -->
				<script id="tech-list-template" type="text/x-handlebars-template">
        		{{#each this}}
		            <div>
		            	<xsl:attribute name="class">product panel panel-default {{this.id}} C{{this.CIAC}} I{{this.CIAI}} A{{this.CIAA}} S{{this.severity}}</xsl:attribute>
						<div class="panel-heading"><span class="large impact">{{this.vendor}}</span></div>
						<div class="panel-body">
							<div class="strong large">Product</div>
							<div>{{this.product}} </div>
							<div>
								<span class="right-5">Version:</span>
								<span>{{this.version}}</span>
							</div>
							<div class="strong large top-10">Severity</div>
							<div>
								<span><xsl:attribute name="class">circleAll {{this.severity}}</xsl:attribute></span>
								<span class="left-5">{{this.severity}}</span>
							</div>
							<div class="strong large top-10">Description</div>
							<div class="panel-text xsmall">
								{{this.description}}
							</div>					
							<div class="strong large top-10">Status</div>
							<div class="top-5">
								<div style="display:inline-block;"><xsl:attribute name="class">circle {{this.CIAC}}</xsl:attribute>C</div> {{this.CIAC}}
								<div style="display:inline-block;"><xsl:attribute name="class">circle {{this.CIAI}}</xsl:attribute>I</div> {{this.CIAI}}
								<div style="display:inline-block;"><xsl:attribute name="class">circle {{this.CIAA}}</xsl:attribute>A</div> {{this.CIAA}}
								<br/>
							</div>
							<div class="strong large top-10">Affected Versions</div>
							<div class="panel-text xsmall">
								{{#each this.versions}}
							        <div>{{this.version_value}}</div>
								{{/each}}
							</div> 
							<div class="strong large top-10">Potential Impacts</div>
							<div>
								<span>Business: </span><span class="right-10">{{this.busCount}}</span>
								<span>Application: </span><span class="right-10">{{this.appCount}}</span>
							</div>
							<div class="top-5">
		            			<button class="btn btn-default btn-sm" style="width:100%">
									<xsl:attribute name="onclick">showImpacts('{{this.id}}')</xsl:attribute>
									<i class="fa fa-sitemap right-5"/><span>Show Impacts</span>
								</button> 
		            		</div>
						</div>
					</div>
				{{/each}}
				</script>

				<script id="impact-list-template" type="text/x-handlebars-template">
					<div class="xlarge fontLight bottom-15">{{this.vendor}}-{{this.product}}</div>
					<div class="row">
						<div class="col-md-6">
							<div class="large impact"><i class="fa fa-users right-10"/>Processes</div>
							<ul class="fa-ul top-10">	
								{{#each this.busimpacts}}   
									<li><i class="fa fa-li fa-caret-right"/>{{this.name}}</li>
								{{/each}}
							</ul>
						</div>
						<div class="col-md-6">
							<div class="large impact"><i class="fa fa-desktop right-10"/>Applications</div>
							<ul class="fa-ul top-10">	
								{{#each this.appimpacts}}
									<li><i class="fa fa-li fa-caret-right"/>{{this.name}}</li>
								{{/each}}
							</ul>
						</div>
					</div>
				</script>


				<xsl:call-template name="Footer"/>
 <script>
            var cveJSON;
            
            productsJSON=[<xsl:apply-templates select="$allTechProds" mode="TechnologyProduct"/>]
            
         $(document).ready(function(){  
             var techListFragment = $("#tech-list-template").html();
                                       techListTemplate = Handlebars.compile(techListFragment);    
            
            var impactListFragment = $("#impact-list-template").html();
                                      impactListTemplate = Handlebars.compile(impactListFragment); 
            $('#nothingToSee').hide();
            $.getJSON("user/data.json", function(cveJSONset) {console.log(cveJSONset);
            return cveJSONset; // this will show the info it in firebug console
            }).done( function(cveJSONset) {
                cveJSON=cveJSONset;
         
            doCompare();
            
            });;
            
            $('#HMLSelect').change(function(d){
             $('.panel').hide();
                if($(this).val()==='all'){
                    $('.panel').show();
                }
                else{
                    $('.S'+$(this).val()).show();
                }
            })
         });
            
            
function doCompare(){
            var prodlist=[];
            var opts =[]
  <!--           cveJSON.CVE_Items.forEach(function(d,i){
            var vends=cveJSON.CVE_Items[i].cve.affects.vendor.vendor_data.forEach(function(e){
                console.log(e.vendor_name+':'+e.product.product_data[0].product_name);
            });
            })
      -->      
            
            
            cveJSON.CVE_Items.forEach(function(d,i){
            cveJSON.CVE_Items[i].cve.affects.vendor.vendor_data.filter(function(d){
            var prods=  productsJSON.filter(function(e){
                    return e.vendor.toUpperCase() ===d.vendor_name.toUpperCase() ; 
                })
            
   console.log(prods)             
            
            if(prods[0]){opts.push(prods[0]);}
        
            if(prods.length &gt;0){
                     productAffected=[];
            prods.forEach(function(e,j){
   
            cveJSON.CVE_Items[i].cve.affects.vendor.vendor_data[0].product.product_data.filter(function(g){
                if(e.product.toUpperCase().replace(' ', '') ===g.product_name.toUpperCase().replace('_', '')){

                prodVersion =g.version.version_data.find(function(v) {
                    if(v.version_value === e.version){
                        productAffected.push(e)}
                    });       
            <!-- for testing only        
            productAffected.push(e);
            -->     
            return g; 
                    }
                    
                })

            if(productAffected&gt;[]){

            prodsA=[];
            prodsA['id']=productAffected[0].id;
            prodsA['vendor']=productAffected[0].vendor;
            prodsA['product']=productAffected[0].product;
            prodsA['version']=productAffected[0].version;
            prodsA['cve_ID']=cveJSON.CVE_Items[i].cve.CVE_data_meta.ID;
            prodsA['severity']=  cveJSON.CVE_Items[i].impact.baseMetricV2.severity
            prodsA['CIAC']=  cveJSON.CVE_Items[i].impact.baseMetricV3.cvssV3.confidentialityImpact; 
            prodsA['CIAI']=  cveJSON.CVE_Items[i].impact.baseMetricV3.cvssV3.integrityImpact; 
            prodsA['CIAA']=  cveJSON.CVE_Items[i].impact.baseMetricV3.cvssV3.availabilityImpact;
            prodsA['versions']=  cveJSON.CVE_Items[i].cve.affects.vendor.vendor_data[0].product.product_data[0].version.version_data;
            prodsA['description']=  cveJSON.CVE_Items[i].cve.description.description_data[0].value;
            prodlist.push(prodsA);
            prodsA['appCount']=productAffected[0].appimpacts.length
            prodsA['busCount']=productAffected[0].busimpacts.length
            prodsA['apps']=productAffected[0].appimpacts;
            prodsA['bus']=productAffected[0].busimpacts;
            
       
            }
            })
     
            ;
                 toShow=uniq(prodlist);
          
            };
              })
            })
            
            toShow.sort(function(a, b) {
                var textA = a.vendor.toUpperCase();
                var textB = b.vendor.toUpperCase();
                return (textA &lt; textB) ? -1 : (textA &gt; textB) ? 1 : 0;
            });
            
            selList=uniqOpt(opts);
            selList.forEach(function(d){
                 $('#productsSelect').append('<option value="'+d.id+'">'+d.vendor+'</option>');
            })
            $(function() {
  
            var select = $('#productsSelect');
            select.html(select.find('option').sort(function(x, y) {
                return $(x).text() > $(y).text() ? 1 : -1;
              }));
              $("#productsSelect")[0].selectedIndex = 0;
            });
            
            $('#prodCards').append(techListTemplate(toShow));  
            
            
         }
            
function getSupplier(vend){
            $('#nothingToSee').hide();
        if(vend==='all'){
             $('.panel').show();  
            }
            else{
            $('.panel').hide();   
            console.log($('.'+vend).length);
            $('.'+vend).show();
            if($('.'+vend).length ===0){
                $('#nothingToSee').show();
                $('#nothingToSee').text('No known current vulnerabilities');
                }
                }
            }            


            
            
function uniq(a) {
            var seen = {};
            return a.filter(function(item) {
                return seen.hasOwnProperty(item.cve_ID) ? false : (seen[item.cve_ID] = true);
            });
        }     
            
        function uniqOpt(a) {
            var seen = {};
            return a.filter(function(item) {
                return seen.hasOwnProperty(item.id) ? false : (seen[item.id] = true);
            });
        }         

    function showImpacts(dataid) { 
            var prods=  productsJSON.filter(function(e){
                    return e.id === dataid; 
                })
           
            $('#modalCards').empty();
            $('#modalCards').append(impactListTemplate(prods[0]));   
            $('#appModal').modal('show');                                  
          }        
        </script>        
			</body>
		</html>
	</xsl:template>

	<xsl:template match="node()" mode="TechnologyProduct">
        <xsl:variable name="thisFamily" select="$allTechProdFamilies[own_slot_value[slot_reference='groups_technology_products']/value=current()/name]"/>
		<xsl:variable name="thisTechProdRoles" select="$allTechProdRoles[own_slot_value[slot_reference = 'role_for_technology_provider']/value = current()/name]"/>
		<xsl:variable name="thisTPUs" select="$allTPUs[own_slot_value[slot_reference = 'provider_as_role']/value = $thisTechProdRoles/name]"/>
		<xsl:variable name="thisTPURels" select="$allTPURels[own_slot_value[slot_reference = ':TO']/value = $thisTPUs/name or own_slot_value[slot_reference = ':FROM']/value = $thisTPUs/name]"/>
		<xsl:variable name="thisTechProdBuildsArchs" select="$allTechProdBuildsArchs[own_slot_value[slot_reference = 'contained_provider_architecture_relations']/value = $thisTPURels/name]"/>
		<xsl:variable name="thisTechProdBuilds" select="$allTechProdBuilds[own_slot_value[slot_reference = 'technology_provider_architecture']/value = $thisTechProdBuildsArchs/name]"/>
		<xsl:variable name="thisAppDeps" select="$allAppDeps[own_slot_value[slot_reference = 'application_deployment_technical_arch']/value = $thisTechProdBuilds/name]"/>
		<xsl:variable name="thisApps" select="$allApps[own_slot_value[slot_reference = 'deployments_of_application_provider']/value = $thisAppDeps/name]"/>
		<xsl:variable name="thisAPRs" select="$allAPRs[own_slot_value[slot_reference = 'role_for_application_provider']/value = $thisApps/name]"/>
		<xsl:variable name="thisAPRstoProcs" select="$allAPRstoProcs[own_slot_value[slot_reference = 'apppro_to_physbus_from_appprorole']/value = $thisAPRs/name]"/>
		<xsl:variable name="thisPhysProcs" select="$allPhysProcsBase[own_slot_value[slot_reference = 'phys_bp_supported_by_app_pro']/value = $thisAPRstoProcs/name]"/>
		<xsl:variable name="thisBusProcs" select="$allBusProcs[own_slot_value[slot_reference = 'implemented_by_physical_business_processes']/value = $thisPhysProcs/name]"/>
		<xsl:variable name="supplier" select="$allTechSuppliers[name = current()/own_slot_value[slot_reference = 'supplier_technology_product']/value]"/> {"id":"<xsl:value-of select="name"/>", "vendor":"<xsl:value-of select="$supplier/own_slot_value[slot_reference = 'name']/value"/>","product":"<xsl:value-of select="$thisFamily/own_slot_value[slot_reference = 'name']/value"/>","productName":"<xsl:value-of select="current()/own_slot_value[slot_reference = 'name']/value"/>","version":"<xsl:value-of select="current()/own_slot_value[slot_reference = 'technology_provider_version']/value"/>","appimpacts":[<xsl:apply-templates select="$thisApps" mode="appImpact"/>],"busimpacts":[<xsl:apply-templates select="$thisBusProcs" mode="busImpact"/>]}, </xsl:template>
	<xsl:template match="node()" mode="appImpact"> {"name":"<xsl:value-of select="current()/own_slot_value[slot_reference = 'name']/value"/>","id":"<xsl:value-of select="current()/name"/>"}, </xsl:template>
	<xsl:template match="node()" mode="busImpact"> {"name":"<xsl:value-of select="current()/own_slot_value[slot_reference = 'name']/value"/>","product":"<xsl:value-of select="current()/own_slot_value[slot_reference = 'name']/value"/>"}, </xsl:template>
</xsl:stylesheet>

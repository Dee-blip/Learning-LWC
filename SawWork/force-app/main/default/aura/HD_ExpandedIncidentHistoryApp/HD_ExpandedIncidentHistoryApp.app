<aura:application implements="force:appHostable" access="global" extends="force:slds">
    <aura:handler name="init" action="{!c.doInit}" value="{!this}" />
	<aura:attribute name="incidentId" type="Id"/>
    <aura:attribute name="rowCount" type="String" default="10000"/>
    <aura:attribute name="startTime" type="DateTime" />
    <aura:attribute name="initComplete" type="Boolean"/>
    
    
    <aura:if isTrue="{!v.initComplete == true}">         
    <c:HDUnifiedHistoryLightningEdition1 recordId="{!v.incidentId}" record_range="{!v.rowCount}" rowCount="{!v.rowCount}"/>
    </aura:if>
</aura:application>
<aura:application implements="force:appHostable,flexipage:availableForAllPageTypes,force:hasRecordId" access="global" extends="force:slds" controller="HD_IncidentDetailController">
    <aura:attribute name="incidentId" type="Id"/>
    <aura:attribute name="startTime" type="DateTime" />
    <aura:attribute name="initComplete" type="Boolean"/>
    <aura:handler name="init" action="{!c.doInit}" value="{!this}" />
    <aura:if isTrue="{!v.initComplete == true}"> 
    <c:HD_Printable_TicketDetails recordId="{!v.incidentId}"/>
    <c:HD_ActionAudit recordId="{!v.incidentId}" startTime="{!v.startTime}" actionName="printTicket"/>
    </aura:if>
</aura:application>
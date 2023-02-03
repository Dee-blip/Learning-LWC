<!--
 * Developer: Sharath Prasanna
 * Enhancement: This Lightning out App is called from ACD2_NavigateToIncident.
 * Date: 18th August 2020
 
Date		Developer		JIRA#		Description
*********************************************************************************************************
9 OCT 2021	Harshil Soni	ACD2-348	Changed HD_CreateIncidentForm component to scCreateNewIncident
*********************************************************************************************************
-->
<aura:application extends="ltng:outApp" access="GLOBAL">
    <aura:dependency resource="c:HD_CreateSRForm" />
     <aura:dependency resource="c:SendDataToVFPage"/>
    <aura:dependency resource="c:scCreateNewIncident" />
    
</aura:application>
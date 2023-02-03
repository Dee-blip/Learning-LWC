<aura:application  extends="force:slds">
    <aura:attribute name="team" type="String" default=""/>
	<aura:attribute name="id" type="String" default="000000000"/>
    <aura:dependency resource="markup://c:HD_Survey_Form"/>
    <c:HD_Survey_Form recordId="{!v.id}" team="{!v.team}"/>
    <!-- c:HD_Survey_Form_star_rating/ -->
    <!-- c:HD_Survey_Form_sentiment/-->
</aura:application>
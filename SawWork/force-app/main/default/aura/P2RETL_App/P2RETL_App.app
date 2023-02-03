<aura:application extends='force:slds'>
    <!-- 1 ,2. Attributes that become true depending on which lightning component is selected -->
    
     <aura:attribute name="IsButton1" default="false" type="boolean"/>
     <aura:attribute name="IsButton2" default="false" type="boolean"/>
     <aura:attribute name="IsButton3" default="false" type="boolean"/>
    

  
    <div class="slds-grid ">
  <div class="slds-col slds-size_2-of-12" style="border-right:1px solid #253045;top: 0; height: 900px; background:#e3e5ed;">
      <lightning:layout >
            <lightning:layoutItem >
                <br/>
                 <br/>
                &nbsp;&nbsp;&nbsp;
            <!-- Lightning component for mapping will be selected -->
           <lightning:button class="{! (v.IsButton1 == false) ? 'button1' : 'button2'}"  label="Mapping"  onclick="{!c.ButtonMethod}"/>
                <br/>
                 <br/>
                
                &nbsp;&nbsp;&nbsp;
                 <!-- Lightning component for Script Generation will be selected -->
           <lightning:button class="{! (v.IsButton2 == false) ? 'button1' : 'button2'}"   label="Script"   onclick="{!c.ButtonMethod}"/>
		   
                 <br/>
                 <br/>
                
                &nbsp;&nbsp;&nbsp;
                
           <lightning:button class="{! (v.IsButton3 == false) ? 'button1' : 'button2'}"   label="SFDC - EDW"   onclick="{!c.ButtonMethod}"/>
		   
                
                
          
          
          </lightning:layoutItem>
      </lightning:layout>
  </div>
  <div class="slds-col slds-size_10-of-12" style="background:#e5eaf9;">
      
          <lightning:layout >
     <lightning:layoutItem >
              
        
                <aura:if isTrue="{!v.IsButton1}">
                   
             <c:P2RETLDisplayMappingSCFF aura:id="one"/> 
				</aura:if>
                <aura:if isTrue="{!v.IsButton2}">
                    
                        
              <c:P2RETLGenerateOracleScript aura:id="two"/> 
                    
                           
                   
				</aura:if>
         
          <aura:if isTrue="{!v.IsButton3}">
                    
                        
              <c:P2RETLDisplayObjectToTable aura:id="three"/> 
                    
                           
                   
				</aura:if>
                
            </lightning:layoutItem>
          
      </lightning:layout>
  </div>
</div>
</aura:application>
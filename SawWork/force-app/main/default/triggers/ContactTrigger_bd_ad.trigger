/***
    ContactTrigger_bd_ad
    @version 1.0
    @author ALI KM <mohhan@akamai.com>
    @Description : This trigger is called on 'before delete' and 'after delete' events on the Contacts object.
    			   It takes care of the following :
    			   	- Capturing Loosing Contact records during Merge for use in updating Winning Contact.Merged 
    			   		ContactId & Contact.Scores Source ContactId fields.
   @History
	--Developer		    --Date			--Change
	ALI KM		  		06/Jul/2012		CR 1741378 Manage scores during Contact merge process
	Sonia Sawhney 		30/Sep/2013		CR 2394210 Need to disable code. Bypass logic for records created through S2S sync
*/
trigger ContactTrigger_bd_ad on Contact (after delete, before delete) {
}
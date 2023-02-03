trigger OCpackageAI on Campaign_Package__c (after insert) {

List<Campaign_Package__c> listofocp =new List<Campaign_Package__c>();

Campaign_Package__c tempocp;

for(Campaign_Package__c ocp:trigger.new)
{
if(ocp.AKAM_Package_ID__c==null)
{
tempocp=new Campaign_Package__c();
tempocp.id=ocp.id;
tempocp.AKAM_Package_ID__c=ocp.PackageAutoID__c;

}
listofocp.add(tempocp);

}


if(listofocp.size()>0)
update listofocp;


}
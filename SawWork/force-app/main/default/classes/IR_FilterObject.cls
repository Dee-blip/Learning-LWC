public class IR_FilterObject {


public class FieldObject
{
public String label { get;set; }
public String api { get;set; }
public String dataType { get;set; }
public Boolean advancedSearch { get;set; }
public Boolean autoComplete { get;set; }
public List<string> autoCompleteList { get;set; }
public String BooleanTrueCondition{get;set;}
public String BooleanFalseCondition{get;set;}
public List<SelectOption> selectOptions{ get { if(selectOptions==null) { selectOptions = new List<SelectOption>();} return selectOptions;}set; }
public String TextboxValue{ get {  if (TextboxValue==null) { TextboxValue= ''; } return TextboxValue; }set;}

public Integer TextboxValueInteger{ get { if (TextboxValueInteger==null) { TextboxValueInteger= 0; } return TextboxValueInteger; } set;}
public Boolean CheckboxValue{get {  if (CheckboxValue==null) { CheckboxValue= false; } return CheckboxValue; } set;}
public String Dateboxa{get { if (Dateboxa==null) { Dateboxa= ''; } return Dateboxa; } set;}
public String Dateboxb{get { if (Dateboxb==null) { Dateboxb= ''; } return Dateboxb; } set;}

}
public List<FieldObject> fieldObjects { get { if(fieldObjects==null) { fieldObjects = new List<FieldObject>(); } return fieldObjects; } set; }

public List<List<string>> AutoCompleteLists{ get { AutoCompleteLists= new List<List<string>>();
for(FieldObject a : fieldObjects)
{
AutoCompleteLists.add(a.autoCompleteList);
}
 return AutoCompleteLists; }set;}



//0 - INTEGER
//1 - STRING
//2 - DATE
//3 - OTHER
private FieldObject createfield(String DataType, String fieldLabelName, String fieldAPIName,String rendered,String Adv, List<String> auto,boolean custom,object defaultValue)
{
//
FieldObject fo = new FieldObject();
fo.label = fieldLabelName;
fo.api = fieldAPIName;
fo.dataType = DataType;
fo.AutoComplete = true;
fo.AutoCompleteList = new List<String>();

for(String tem :auto)
    {    	
    fo.AutoCompleteList.add('"' + tem + '"');
    fo.selectOptions.add(new SelectOption(tem,tem));
    }
if((String)Adv == 'True')
{
   fo.advancedSearch = true;
}
else
{
   fo.advancedSearch = false;
}
if(defaultValue!=null)
{
if(DataType=='string')
{
fo.TextboxValue=(String)defaultValue;
}
else if (DataType=='Boolean')
{
fo.CheckboxValue=(Boolean)defaultValue;
}
else if (DataType=='integer')
{
fo.TextboxValueInteger = (Integer)defaultValue;

} 
}

if(!custom)
{
fieldObjects.add(fo);
return null;
}
else
return fo;
//
   
}




public void AddField(String DataType, String fieldLabelName, String fieldAPIName,String Adv)
{
    try
    {
        if(DataType!=null && DataType !='')
        {
            String DT = '';
            if(DataType.equalsIgnoreCase('string'))
            {
                DT='string';
            }
            else if (DataType.equalsIgnoreCase('decimal')||DataType.equalsIgnoreCase('double')||DataType.equalsIgnoreCase('integer')||DataType.equalsIgnoreCase('long'))
            {
                DT='integer';
            }
            else if (DataType.equalsIgnoreCase('date')||DataType.equalsIgnoreCase('datetime'))
            {
                DT='date';
            }
             else if (DataType.equalsIgnoreCase('boolean')||DataType.equalsIgnoreCase('bool'))
            {
                DT='Boolean';
            }
            else
            {
                DT=DataType;
            }
            if(fieldLabelName!=null && fieldLabelName!='' && fieldAPIName !=null && fieldAPIName !='')
            {  
               createField(DT,fieldLabelName,fieldAPIName,'True',Adv,new List<String>(),false,null);
            }
        }
       
    }
    catch(Exception e)
    {
    
    }
}
public void AddField(String DataType, String fieldLabelName, String fieldAPIName,String Adv,List<String> auto,object defaultValue)
{
    try
    {
        if(DataType!=null && DataType !='')
        {
            String DT = '';
            if(DataType.equalsIgnoreCase('string'))
            {
                DT='string';
            }
            else if (DataType.equalsIgnoreCase('decimal')||DataType.equalsIgnoreCase('double')||DataType.equalsIgnoreCase('integer')||DataType.equalsIgnoreCase('long'))
            {
                DT='integer';
            }
            else if (DataType.equalsIgnoreCase('date')||DataType.equalsIgnoreCase('datetime'))
            {
                DT='date';
            }
            else if (DataType.equalsIgnoreCase('boolean')||DataType.equalsIgnoreCase('bool'))
            {
                DT='Boolean';
            }
            else
            {
                DT=DataType;
            }
            if(fieldLabelName!=null && fieldLabelName!='' && fieldAPIName !=null && fieldAPIName !='')
            {   
                createField(DT,fieldLabelName,fieldAPIName,'True',Adv,auto,false,defaultValue);
            }
        }
       
    }
    catch(Exception e)
    {
    
    }
}
public void AddField(String DataType, String fieldLabelName, String fieldAPIName,String Adv,List<String> auto)
{
    try
    {
        if(DataType!=null && DataType !='')
        {
            String DT = '';
            if(DataType.equalsIgnoreCase('string'))
            {
                DT='string';
            }
            else if (DataType.equalsIgnoreCase('decimal')||DataType.equalsIgnoreCase('double')||DataType.equalsIgnoreCase('integer')||DataType.equalsIgnoreCase('long'))
            {
                DT='integer';
            }
            else if (DataType.equalsIgnoreCase('date')||DataType.equalsIgnoreCase('datetime'))
            {
                DT='date';
            }
            else if (DataType.equalsIgnoreCase('boolean')||DataType.equalsIgnoreCase('bool'))
            {
                DT='Boolean';
            }
            else
            {
                DT=DataType;
            }
            if(fieldLabelName!=null && fieldLabelName!='' && fieldAPIName !=null && fieldAPIName !='')
            {   
                createField(DT,fieldLabelName,fieldAPIName,'True',Adv,auto,false,null);
            }
        }
       
    }
    catch(Exception e)
    {
    
    }
}
public void AddField(String DataType, String fieldLabelName, String fieldAPIName)
{
    try
    {
        if(DataType!=null && DataType !='')
        {
            String DT = '';
            if(DataType.equalsIgnoreCase('string'))
            {
                DT='string';
            }
            else if (DataType.equalsIgnoreCase('decimal')||DataType.equalsIgnoreCase('double')||DataType.equalsIgnoreCase('integer')||DataType.equalsIgnoreCase('long'))
            {
                DT='integer';
            }
            else if (DataType.equalsIgnoreCase('date')||DataType.equalsIgnoreCase('datetime'))
            {
                DT='date';
            }
            else if (DataType.equalsIgnoreCase('boolean')||DataType.equalsIgnoreCase('bool'))
            {
                DT='Boolean';
            }
            else
            {
                DT=DataType;
            }
            if(fieldLabelName!=null && fieldLabelName!='' && fieldAPIName !=null && fieldAPIName !='')
            {  
               createField(DT,fieldLabelName,fieldAPIName,'True','false',new List<String>(),false,null);
            }
        }
      
    }
    catch(Exception e)
    {
    
    }
}
public void AddField(String DataType, String fieldLabelName, String fieldAPIName,List<String> auto)
{
    try
    {
        if(DataType!=null && DataType !='')
        {
            String DT = '';
            if(DataType.equalsIgnoreCase('string'))
            {
                DT='string';
            }
            else if (DataType.equalsIgnoreCase('decimal')||DataType.equalsIgnoreCase('double')||DataType.equalsIgnoreCase('integer')||DataType.equalsIgnoreCase('long'))
            {
                DT='integer';
            }
            else if (DataType.equalsIgnoreCase('date')||DataType.equalsIgnoreCase('datetime'))
            {
                DT='date';
            }
            else if (DataType.equalsIgnoreCase('boolean')||DataType.equalsIgnoreCase('bool'))
            {
                DT='Boolean';
            }
            else
            {
                DT=DataType;
            }
            if(fieldLabelName!=null && fieldLabelName!='' && fieldAPIName !=null && fieldAPIName !='')
            {   
               createField(DT,fieldLabelName,fieldAPIName,'True','false',auto,false,null);
            }
        }
       
        
    }
    catch(Exception e)
    {
    
    }
}

public void AddCustomBooleanField( String fieldLabelName,String boolTrueCondition, String boolFalseCondition )
{
    try
    {
       
            String DT;
            
                DT='Boolean';
            
            if(fieldLabelName!=null && fieldLabelName!='' && boolTrueCondition  !=null && boolTrueCondition !='')
            {  
               FieldObject temp = createField(DT,fieldLabelName,'','True','True',new List<String>(),true,null);
               temp.BooleanTrueCondition = boolTrueCondition;
               temp.BooleanFalseCondition =boolFalseCondition ;
               fieldObjects.add(temp);
            }
        
        
       
    }
    catch(Exception e)
    {
    
    }
}

}
public class MultiSelectComponentController {

    public String Chosen { get; set; }

    public String Available { get; set; }
public List<selectOption> options {get{if(options==null){options = new List<selectOption>();}return options;}set;}
public List<selectOption> selectedOptions {get{if(selectedOptions==null){selectedOptions = new List<selectOption>();}return selectedOptions;}set;}
public List<String> selected {get;set;}
public List<String> deselected {get;set;}
public void selecting() {   
 for(String toSelect: selected) {
  Integer i = 0;
  While(i<options.size()) {
  if(options[i].getvalue()==toSelect) {
   selectedOptions.add(new SelectOption(toSelect,options[i].getlabel()));
   options.remove(i);
  }                    
  i++;
  }
 }
}
 
public void deselecting() { 
 for(String toDeselect: deselected) {            
  Integer i = 0;
  While(i<selectedOptions.size()) {
  if(selectedOptions[i].getvalue()==toDeselect) {
   options.add(new SelectOption(toDeselect, selectedOptions[i].getlabel()));
   selectedOptions.remove(i);
  }                    
  i++;
  }
 }  
}

}
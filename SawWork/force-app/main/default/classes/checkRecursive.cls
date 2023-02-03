global class checkRecursive {
static boolean firstRun = true;
    public static boolean isFirstRun(){
    if(firstRun){
      firstRun = false;
      return true;
    }else{
        return firstRun;
    }
    }
   /*
    
    private static boolean blnAlreadyDone = false;

public static boolean hasAlreadyDone(){ 
    return blnAlreadyDone;
}

public static void setAlreadyDone() {
    blnAlreadyDone = true;  
}
    public static boolean reEntry  = false; 
    public static Boolean doNotRunTrigger = false;

    public static void setDoNotRunTrigger(){
        doNotRunTrigger = true;
    }

    public static Boolean shouldRunTrigger() {
        return !doNotRunTrigger;
    }*/
}
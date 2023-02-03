public virtual class SupportEmployee{

    private User user;
 
    private integer primaryAccCount;
 
    private integer secondaryAccCount;
 
    private integer otherAccCount;
    
    private integer primarySupport;
    
    private integer secondarySupport;
    
    private integer otherSupport;
    
    private Set<String> primarySupportIds = new Set<String>();
    
    private Set<String> secondarySupportIds = new Set<String>();
    
    private Set<String> otherSupportIds = new Set<String>();
    
    public integer getPrimarySupport(){return primarySupport;}
    
    public void setPrimarySupport(integer primarySupport){
        this.primarySupport = primarySupport;
    }
    
    public integer getOtherSupport(){return otherSupport;}
    
    public void setOtherSupport(integer otherSupport){
        this.otherSupport = otherSupport;
    }
    
    public integer getSecondarySupport(){return secondarySupport;}
    
    public void setSecondarySupport(integer secondarySupport){
        this.secondarySupport = secondarySupport;
    }
    
    public Set<String> getPrimarySupportIds(){return primarySupportIds;}
    
    public void setPrimarySupportIds(Set<String> primarySupportIds){
        this.primarySupportIds = primarySupportIds;
    }    
 	
    public Set<String> getSecondarySupportIds(){return secondarySupportIds;}
    
    public void setSecondarySupportIds(Set<String> secondarySupportIds){
        this.secondarySupportIds = secondarySupportIds;
    }    
 
    public Set<String> getOtherSupportIds(){return otherSupportIds;}
    
    public void setOtherSupportIds(Set<String> otherSupportIds){
        this.otherSupportIds = otherSupportIds;
    } 
    
    public integer getPrimaryAccCount(){return primaryAccCount;}
    
    public void setPrimaryAccCount(integer primaryAccCount){
        this.primaryAccCount = primaryAccCount;
    }
    
    
    public integer getSecondaryAccCount(){return secondaryAccCount;}
    
    public void setSecondaryAccCount(integer secondaryAccCount){
        this.secondaryAccCount = secondaryAccCount;
    }
    
    public integer getOtherAccCount(){return otherAccCount;}
    
    
    public void setOtherAccCount(integer otherAccCount){
        this.otherAccCount = otherAccCount;
    }
    
    public User getUser(){return user;}
    
    public void setUser(User user){
        this.user = user;
    }
    
    


}
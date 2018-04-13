
Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue

Function GetUserAccessReport($WebAppURL, $FileUrl)
{
 #Get All Site Collections of the WebApp
 $SiteCollections = Get-SPSite -WebApplication $WebAppURL -Limit All

#Write CSV- TAB Separated File) Header
"URL `t Site/List `t Title `t PermissionType `t Permissions  `t LoginName" | out-file $FileUrl


	#Check Web Application Policies
	$WebApp= Get-SPWebApplication $WebAppURL

	foreach ($Policy in $WebApp.Policies) 
  	{
	 	#Check if the search users is member of the group
		#if($Policy.UserName -eq $SearchUser)
		  #	{
				#Write-Host $Policy.UserName
	 			$PolicyRoles=@()
		 		foreach($Role in $Policy.PolicyRoleBindings)
				{
					$PolicyRoles+= $Role.Name +";"
				}
				#Write-Host "Permissions: " $PolicyRoles
				
				"$($AdminWebApp.URL) `t Web Application `t $($AdminSite.Title)`t  Web Application Policy `t $($PolicyRoles) `t $($Policy.UserName)" | Out-File $FileUrl -Append
			#}
 	 }
  
  #Loop through all site collections
   foreach($Site in $SiteCollections) 
    {
	  #Check Whether the Search User is a Site Collection Administrator
	  foreach($SiteCollAdmin in $Site.RootWeb.SiteAdministrators)
      	{
				"$($Site.RootWeb.Url) `t Site `t $($Site.RootWeb.Title)`t Site Collection Administrator `t Site Collection Administrator `t $($SiteCollAdmin.LoginName)" | Out-File $FileUrl -Append
		
		}
  
	   #Loop throuh all Sub Sites
       foreach($Web in $Site.AllWebs) 
       {	
			if($Web.HasUniqueRoleAssignments -eq $True)
            	{
		        #Get all the users granted permissions to the list
	            foreach($WebRoleAssignment in $Web.RoleAssignments ) 
	                { 
	                  #Is it a User Account?
						if($WebRoleAssignment.Member.userlogin)    
							{
							  			#Get the Permissions assigned to user
									 	$WebUserPermissions=@()
									    foreach ($RoleDefinition  in $WebRoleAssignment.RoleDefinitionBindings)
									   	{
				                    	    $WebUserPermissions += $RoleDefinition.Name +";"
				                       	}
										#write-host "with these permissions: " $WebUserPermissions
										#Send the Data to Log file
										"$($Web.Url) `t Site `t $($Web.Title)`t Direct Permission `t $($WebUserPermissions)  `t $($WebRoleAssignment.Member.LoginName)" | Out-File $FileUrl -Append
							}
					#Its a SharePoint Group, So search inside the group and check if the user is member of that group
					else  
						{
                        foreach($user in $WebRoleAssignment.member.users)
                            {
								    #Get the Group's Permissions on site
									$WebGroupPermissions=@()
							    	foreach ($RoleDefinition  in $WebRoleAssignment.RoleDefinitionBindings)
							   		{
		                    	  		$WebGroupPermissions += $RoleDefinition.Name +";"
		                       		}
									#write-host "Group has these permissions: " $WebGroupPermissions
									
									#Send the Data to Log file
									"$($Web.Url) `t Site `t $($Web.Title)`t Member of $($WebRoleAssignment.Member.Name) Group `t $($WebGroupPermissions) `t $($user.LoginName)" | Out-File $FileUrl -Append
							}
						}
               	    }
				}
				
				#********  Check Lists with Unique Permissions ********/
		            foreach($List in $Web.lists)
		            {
		                if($List.HasUniqueRoleAssignments -eq $True -and ($List.Hidden -eq $false))
		                {
		                   #Get all the users granted permissions to the list
				            foreach($ListRoleAssignment in $List.RoleAssignments ) 
				                { 
				                  #Is it a User Account?
									if($ListRoleAssignment.Member.userlogin)    
										{
										   
													#Get the Permissions assigned to user
												 	$ListUserPermissions=@()
												    foreach ($RoleDefinition  in $ListRoleAssignment.RoleDefinitionBindings)
												   	{
							                    	    $ListUserPermissions += $RoleDefinition.Name +";"
							                       	}
													#write-host "with these permissions: " $ListUserPermissions
													
													#Send the Data to Log file
													"$($List.ParentWeb.Url)/$($List.RootFolder.Url) `t List `t $($List.Title)`t Direct Permission1 `t $($ListUserPermissions)  `t $($ListRoleAssignment.Member)" | Out-File $FileUrl -Append
										}
										#Its a SharePoint Group, So search inside the group and check if the user is member of that group
									else  
										{
					                        foreach($user in $ListRoleAssignment.member.users)
					                            {
													    #Get the Group's Permissions on site
														$ListGroupPermissions=@()
												    	foreach ($RoleDefinition  in $ListRoleAssignment.RoleDefinitionBindings)
												   		{
							                    	  		$ListGroupPermissions += $RoleDefinition.Name +";"
							                       		}
														#write-host "Group has these permissions: " $ListGroupPermissions
														
														#Send the Data to Log file
														"$($Web.Url) `t List `t $($List.Title)`t Member of $($ListRoleAssignment.Member.Name) Group `t $($user.LoginName) `t $($user.LoginName)" | Out-File $FileUrl -Append

												}
									}	
			               	    }
				            }
		            }
				}	
			}
					
		}

#Call the function to Check User Access
#GetUserAccessReport "http://sp2013" "c:\users_PermisionReport.csv"


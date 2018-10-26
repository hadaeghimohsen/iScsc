SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[InstallDatabase]
	-- Add the parameters for the stored procedure here
	@X XML
AS
BEGIN
   BEGIN TRY   
   BEGIN TRAN T_INSTALLDB
   -- Delete Record From Database
   DELETE dbo.Pre_Expense;
   DELETE dbo.Account;
   DELETE dbo.Account_Detail;
   DELETE dbo.Aggregation_Operation;
   DELETE dbo.Aggregation_Operation_Detail;
   DELETE dbo.Attendance;
   DELETE dbo.Buffet;
   DELETE dbo.Payment_Expense;
   DELETE dbo.Misc_Expense;
   DELETE dbo.Member_Ship
   DELETE dbo.Fighter_Public;
   DELETE dbo.Calculate_Calorie;
   DELETE dbo.Campitition;
   DELETE dbo.Meeting_Comment;
   DELETE dbo.Present_Comment;
   DELETE dbo.Present;
   DELETE dbo.Meeting;
   DELETE dbo.Committee;
   DELETE dbo.Exam;
   DELETE dbo.Heart_Zone;
   DELETE dbo.Physical_Fitness;
   DELETE dbo.Test;
   DELETE dbo.Member_Ship;
   DELETE dbo.Request_Regulation_History;
   DELETE dbo.Payment_Detail;
   DELETE dbo.Payment_Discount;
   DELETE dbo.Payment_Method;
   DELETE dbo.Payment_Check;
   DELETE dbo.Payment;
   DELETE dbo.Gain_Loss_Rail_Detail;
   DELETE dbo.Gain_Loss_Rial;
   DELETE dbo.Request_Row;
   DELETE dbo.Request;
   UPDATE dbo.Club_Method SET COCH_FILE_NO = NULL;
   DELETE dbo.Calculate_Expense_Coach
   DELETE dbo.Base_Calculate_Expense;
   DELETE dbo.Planning_Overview;
   DELETE dbo.Fighter;
   DELETE dbo.Club_Method;
   DELETE dbo.Computer_Action;
   DELETE dbo.App_Base_Define;
   DELETE dbo.Cando_Block_Unit;
   DELETE dbo.Cando_Block;
   DELETE dbo.Cando;
   DELETE dbo.Method;
   DELETE dbo.Distance_Category
   DELETE dbo.Category_Belt;
   DELETE dbo.Dresser_Attendance;
   DELETE dbo.Dresser;
   DELETE dbo.Expense_Item;
   DELETE dbo.Group_Expense;
   DELETE dbo.Holidays;
   DELETE dbo.Organ WHERE CODE != '00';
   DELETE dbo.Sub_Unit WHERE CODE != '0000';
   DELETE dbo.Session;
   DELETE dbo.Session_Meeting;
   DELETE dbo.Step_History_Summery;
   DELETE dbo.Step_History_Detail;

   -- Save Host Info
   IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'iProject')
	BEGIN
	   RAISERROR (N'iProject Database is not install, Please First Install iProject', 16, 1);
	   RETURN -1;
	END 
	
   /*
   '<Request Rqtp_Code="ManualSaveHostInfo">
      <Database>iProject</Database>
      <Dbms>SqlServer</Dbms>
      <User>scott</User>
      <Computer name="DESKTOP-LB0GKTR" 
                ip="192.168.158.1" 
                mac="00:50:56:C0:00:01" 
                cpu="BFEBFBFF000206A7" />
    </Request>'
   */
   
   DECLARE  @RqtpCode      VARCHAR(30)
           ,@ComputerName VARCHAR(50)
           ,@IPAddress    VARCHAR(15)
           ,@MacAddress   VARCHAR(17)
           ,@Cpu      VARCHAR(30)
           ,@UserName     VARCHAR(250)
           ,@UserId       BIGINT
           ,@DatabaseTest VARCHAR(3)
           ,@InstallLicenseKey NVARCHAR(4000);
   
   SELECT @ComputerName = @X.query('//Computer').value('(Computer/@name)[1]', 'VARCHAR(50)')
         ,@Cpu = @X.query('//Computer').value('(Computer/@cpu)[1]', 'VARCHAR(30)')
         ,@DatabaseTest = @X.query('//Params').value('(Params/@databasetest)[1]', 'VARCHAR(3)')
         ,@InstallLicenseKey = @X.query('//Params').value('(Params/@licensekey)[1]', 'NVARCHAR(4000)');
   
   -- Save Datasource and Connection
   IF NOT EXISTS(
      SELECT * 
        FROM iProject.Report.DataSource 
       WHERE (
         (@DatabaseTest = '002' AND Database_Alias = 'iScsc001') OR 
         (@DatabaseTest = '001' AND Database_Alias = 'iScsc')
       )
   )   
   BEGIN   
      IF @DatabaseTest = '001'
         INSERT INTO iProject.Report.DataSource
         ( ID ,ShortCut ,DatabaseServer ,IPAddress ,Port ,
           Database_Alias ,[Database] ,UserID ,Password ,TitleFa ,
           IsDefault ,IsActive ,IsVisible ,SUB_SYS 
         )
         VALUES  
         ( 2 ,2 ,1 ,@ComputerName,0 , 
           'iScsc' ,'iScsc' ,'' , '' , N'اطلاعات اصلی' , 
           1 , 1 , 1 , 5  );
      ELSE
         INSERT INTO iProject.Report.DataSource
         ( ID ,ShortCut ,DatabaseServer ,IPAddress ,Port ,
           Database_Alias ,[Database] ,UserID ,Password ,TitleFa ,
           IsDefault ,IsActive ,IsVisible ,SUB_SYS 
         )
         VALUES  
         ( 3 ,3 ,1 ,@ComputerName,0 , 
           'iScsc' ,'iScsc001' ,'' , '' , N'اطلاعات تستی' , 
           1 , 1 , 1 , 5  ); 
   END 
        
   DECLARE @XT XML;
   IF @DatabaseTest = '001'
   begin
      SELECT @XT = (
         SELECT 'ManualSaveHostInfo' AS '@Rqtp_Code'
               ,'iScsc' AS 'Database'
               ,'SqlServer' AS 'Dbms'
               ,'artauser' AS 'User'
               ,'installing' AS 'SystemStatus'
               ,@X.query('//Computer').value('(Computer/@name)[1]', 'VARCHAR(50)') AS 'Computer/@name'
               ,@X.query('//Computer').value('(Computer/@mac)[1]', 'VARCHAR(17)') AS 'Computer/@mac'
               ,@X.query('//Computer').value('(Computer/@ip)[1]', 'VARCHAR(15)') AS 'Computer/@ip'
               ,@X.query('//Computer').value('(Computer/@cpu)[1]', 'VARCHAR(30)') AS 'Computer/@cpu'
           FOR XML PATH('Request')
      );
      
      EXEC iProject.DataGuard.SaveHostInfo @X = @XT;
   END    
   ELSE 
   BEGIN
      SELECT @XT = (
         SELECT 'ManualSaveHostInfo' AS '@Rqtp_Code'
               ,'iScsc' AS 'Database'
               ,'SqlServer' AS 'Dbms'
               ,'demo' AS 'User'
               ,'installing' AS 'SystemStatus'
               ,@X.query('//Computer').value('(Computer/@name)[1]', 'VARCHAR(50)') AS 'Computer/@name'
               ,@X.query('//Computer').value('(Computer/@mac)[1]', 'VARCHAR(17)') AS 'Computer/@mac'
               ,@X.query('//Computer').value('(Computer/@ip)[1]', 'VARCHAR(15)') AS 'Computer/@ip'
               ,@X.query('//Computer').value('(Computer/@cpu)[1]', 'VARCHAR(30)') AS 'Computer/@cpu'
           FOR XML PATH('Request')
      );
      
      EXEC iProject.DataGuard.SaveHostInfo @X = @XT;
   END;
   
   UPDATE iProject.DataGuard.Sub_System SET STAT = '002', INST_STAT = '002', CLNT_LICN_DESC = NULL, SRVR_LICN_DESC = NULL, LICN_TYPE = NULL, LICN_TRIL_DATE = NULL, INST_LICN_DESC = @InstallLicenseKey WHERE SUB_SYS IN (5);   
   
   IF @DatabaseTest = '001'
      INSERT INTO iProject.Global.Access_User_Datasource
      ( USER_ID ,DSRC_ID ,STAT ,ACES_TYPE ,
        HOST_NAME )
      SELECT id, 2, '002', '001', @Cpu
        FROM iProject.DataGuard.[User] u
       WHERE ShortCut IN (16, 21)
         AND NOT EXISTS(
             SELECT *
               FROM iProject.Global.Access_User_Datasource a
              WHERE a.USER_ID = u.ID
                AND a.DSRC_ID = 2
         );
   ELSE
      INSERT INTO iProject.Global.Access_User_Datasource
      ( USER_ID ,DSRC_ID ,STAT ,ACES_TYPE ,
        HOST_NAME )
      SELECT id, 0, '002', '001', @Cpu
        FROM iProject.DataGuard.[User] u
       WHERE ShortCut IN (22)
         AND NOT EXISTS(
             SELECT *
               FROM iProject.Global.Access_User_Datasource a
              WHERE a.USER_ID = u.ID
                AND a.DSRC_ID = 3
         );
       
   COMMIT TRAN T_INSTALLDB;
   END TRY
   BEGIN CATCH
      DECLARE @ErrorMessage NVARCHAR(MAX);
      SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN T_INSTALLDB;
   END CATCH;   
END
GO

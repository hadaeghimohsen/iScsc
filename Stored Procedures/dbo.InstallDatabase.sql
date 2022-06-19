SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[InstallDatabase]
	-- Add the parameters for the stored procedure here
	@X XML
AS
BEGIN
   DECLARE @Emptydb VARCHAR(3);
   SELECT @Emptydb = @X.query('//Params').value('(Params/@emptydb)[1]', 'VARCHAR(3)');
   BEGIN TRY   
   
   IF @Emptydb = '002'
   BEGIN
      -- Delete Record From Database
      DELETE dbo.Basic_Calculate_Discount;
      DELETE dbo.Pre_Expense;
      DELETE dbo.Account;
      DELETE dbo.Account_Detail;
      DELETE dbo.Aggregation_Operation;
      DELETE dbo.Aggregation_Operation_Detail;
      DELETE dbo.Dresser_Attendance;
      DELETE dbo.Dresser;
      DELETE dbo.Attendance;
      DELETE dbo.Buffet;
      DELETE dbo.Payment_Expense;
      DELETE dbo.Member_Ship_Mark;
      DELETE dbo.Misc_Expense_Detail;
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
      --DELETE dbo.Group_Expense;
      DELETE dbo.Holidays;
      DELETE dbo.Organ WHERE CODE != '00';
      DELETE dbo.Sub_Unit WHERE CODE != '0000';
      DELETE dbo.Session;
      DELETE dbo.Session_Meeting;
      DELETE dbo.Step_History_Summery;
      DELETE dbo.Step_History_Detail;
      DELETE dbo.User_Club_Fgac;
      DELETE dbo.User_Region_Fgac;
      DELETE dbo.Settings;
      UPDATE dbo.Message_Broadcast SET CLUB_CODE = NULL, STAT = '001', TELG_STAT = '001', LINE_TYPE = '001', CLUB_NAME = NULL, DEBT_PRIC = NULL, MIN_NUMB_ATTN_RMND = NULL, MIN_NUMB_DAY_RMND = NULL, INSR_FNAM_STAT = '001', INSR_CNAM_STAT = '001', MSGB_TEXT = NULL, FROM_DATE = NULL, TO_DATE = NULL;
      DELETE dbo.Club;
   END;
   
   BEGIN TRAN T_INSTALLDB
   
   IF @Emptydb = '002'
   BEGIN
      -- Insert Into Default Value
      INSERT INTO dbo.Club ( REGN_PRVN_CNTY_CODE ,REGN_PRVN_CODE ,REGN_CODE ,CODE ,NAME )
      VALUES  ( '001' , '017' , '001' , 0 , N'RelaySoft' );
      
      DECLARE @ClubCode BIGINT;
      SELECT @ClubCode = Code FROM dbo.Club;
      
      INSERT INTO dbo.User_Region_Fgac( FGA_CODE ,REGN_PRVN_CNTY_CODE ,REGN_PRVN_CODE ,REGN_CODE ,SYS_USER ,REC_STAT ,VALD_TYPE )
      SELECT dbo.GNRT_NVID_U(), '001', '017', '001', USER_DB, '002', '002' FROM dbo.V#Users;
      
      INSERT INTO dbo.User_Club_Fgac ( FGA_CODE ,CLUB_CODE ,SYS_USER ,REC_STAT ,VALD_TYPE )
      SELECT dbo.GNRT_NVID_U(), @ClubCode, USER_DB, '002', '002' FROM dbo.V#Users;
      
      DECLARE @p0 SMALLINT = SUBSTRING(dbo.GET_MTOS_U(GETDATE()), 1, 4),@p1 varchar(3) = '001',@p3 DATETIME = GETDATE(),@p4 nvarchar(4000) = 'RelaySoft',@p5 DATETIME = GETDATE(),@p6 DATETIME = DATEADD(YEAR, 1, GETDATE()),@p7 REAL = 0,@p8 REAL = 0,@p9 varchar(3) = '002',@p10 BIGINT;      
		EXEC [dbo].[INS_REGL_P] @Year = @p0, @Type = @p1, @LettNo = @p0, @LettDate = @p3, @LettOwnr = @p4, @StrtDate = @p5, @EndDate = @p6, @TaxPrct = @p7, @DutyPrct = @p8, @AmntType = @p9, @InsrPric = @p10;
		
		UPDATE dbo.Regulation SET REGL_STAT = '001' WHERE YEAR != @p0 AND [TYPE] = '001';
		UPDATE dbo.Regulation SET REGL_STAT = '002' WHERE YEAR = @p0 AND [TYPE] = '001';
		DELETE dbo.Regulation WHERE YEAR != @p0 AND [TYPE] = '001';
		
		INSERT INTO dbo.Expense_Item ( CODE ,RQTP_CODE ,RQTT_CODE ,EPIT_DESC ,TYPE ) VALUES (0, '001', '001', N'شهریه', '001');
		
		EXEC dbo.INS_MTOD_P @Mtod_Desc = N'فروشگاه اینترنتی',@Mtod_Code = 0,@Epit_Type = '001',@Dflt_Stat = '001',@Mtod_Stat = '002',@Chck_Attn_Alrm = '001',@Natl_Code = '',@Shar_Stat = '001';
		
		DECLARE @MtodCode BIGINT;
		SELECT TOP 1 @MtodCode = CODE FROM dbo.Method;
		EXEC [dbo].[INS_CTGY_P] @Mtod_Code = @MtodCode, @Ctgy_Desc = N'سبد خرید', @Epit_Type = '001', @Numb_Of_Attn_Mont = 0, @Numb_Cycl_Day = 0, @Numb_Mont_Ofer = 0, @Pric = 0, @Dflt_Stat = '001', @Ctgy_Stat = '002', @Gust_Numb = 0;
		
		DECLARE @Xtemp XML = '<Process><Request rqid="0" rqtpcode="001" rqttcode="003"><Fighter fileno="0"><Frst_Name>عمومی آقایان</Frst_Name><Last_Name>مربی</Last_Name><Fath_Name/><Coch_Deg/><Coch_Crtf_Date>2022-06-17</Coch_Crtf_Date><Gudg_Deg/><glob_Code/><Sex_Type>001</Sex_Type><Natl_Code>0</Natl_Code><Brth_Date>2022-06-17</Brth_Date><Cell_Phon/><Tell_Phon/><Type>003</Type><Post_Adrs/><Emal_Adrs/><Insr_Numb/><Insr_Date>2021-06-17</Insr_Date><Educ_Deg/><Mtod_Code>'+ CAST(@MtodCode AS VARCHAR(30)) + '</Mtod_Code><Dise_Code/><Calc_Expn_Type/><Blod_grop/><Fngr_Prnt/><Dpst_Acnt_Slry_Bank/><Dpst_Acnt_Slry/><Chat_Id/></Fighter></Request></Process>';
		EXEC [dbo].[ADM_MSAV_F] @X = @Xtemp;
		
		SET @Xtemp = '<Process><Request rqid="0" rqtpcode="001" rqttcode="003"><Fighter fileno="0"><Frst_Name>عمومی بانوان</Frst_Name><Last_Name>مربی</Last_Name><Fath_Name/><Coch_Deg/><Coch_Crtf_Date>2022-06-17</Coch_Crtf_Date><Gudg_Deg/><glob_Code/><Sex_Type>002</Sex_Type><Natl_Code>0</Natl_Code><Brth_Date>2022-06-17</Brth_Date><Cell_Phon/><Tell_Phon/><Type>003</Type><Post_Adrs/><Emal_Adrs/><Insr_Numb/><Insr_Date>2021-06-17</Insr_Date><Educ_Deg/><Mtod_Code>'+ CAST(@MtodCode AS VARCHAR(30)) + '</Mtod_Code><Dise_Code/><Calc_Expn_Type/><Blod_grop/><Fngr_Prnt/><Dpst_Acnt_Slry_Bank/><Dpst_Acnt_Slry/><Chat_Id/></Fighter></Request></Process>';
		EXEC [dbo].[ADM_MSAV_F] @X = @Xtemp;
   END
   
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
               ,'installing' AS '@SystemStatus'
               ,'iScsc' AS 'Database'
               ,'SqlServer' AS 'Dbms'
               ,'artauser' AS 'User'               
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
               ,'installing' AS '@SystemStatus'
               ,'iScsc' AS 'Database'
               ,'SqlServer' AS 'Dbms'
               ,'demo' AS 'User'               
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
      SELECT id, 3, '002', '001', @Cpu
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

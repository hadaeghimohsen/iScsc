SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[STNG_SAVE_P]
	@X XML
	/*
	<Config type="">
	   <Settings/>
	   <FgaURegn/>
	   <FgaUClub/>
	</Config>
	*/
AS
BEGIN
   BEGIN TRY
   BEGIN TRAN STNG_SAVE_P_TRAN
      DECLARE @ErrorMessage NVARCHAR(MAX);
      DECLARE @ConfigType VARCHAR(3);
      SELECT @ConfigType = @x.query('Config').value('(Config/@type)[1]', 'VARCHAR(3)');
      
      DECLARE @PrvnCode VARCHAR(3)
             ,@RegnCode VARCHAR(3)
             ,@SysUser  VARCHAR(250)
             ,@MstrSysUser VARCHAR(250)
             ,@ClubCode BIGINT
             ,@Type     VARCHAR(3);
             
      IF LEN(@ConfigType) = 0 OR @ConfigType IS NULL
      BEGIN
	      DECLARE @BackUp BIT
	             ,@BackupAppExit BIT
	             ,@BackupInTred BIT
	             ,@BackupOptnPath BIT
	             ,@BackupRootPath NVARCHAR(MAX)
	             ,@BackupOptnPathAdrs NVARCHAR(MAX)
	             ,@DresStat VARCHAR(3)
	             ,@DresAuto VARCHAR(3)
	             ,@MoreFighOneDres VARCHAR(3)
	             ,@MoreAttnSesn VARCHAR(3)
	             ,@NotfStat VARCHAR(3)
	             ,@NotfExpDay INT
	             ,@AttnSysmType VARCHAR(3)
	             ,@CommPortName VARCHAR(30)
	             ,@BandRate INT
	             ,@BarCodeDataType VARCHAR(3)
	             ,@Atn3EvntActnType VARCHAR(3)
	             ,@IPAddr VARCHAR(15)
	             ,@PortNumb INT
	             ,@AttnCompConct VARCHAR(30)
	             ,@Atn1EvntActnType VARCHAR(3)
                ,@IPAdr2 VARCHAR(15)
	             ,@PortNum2 INT
	             ,@AttnCompCnc2 VARCHAR(30)	             
	             ,@Atn2EvntActnType VARCHAR(3)
	             ,@AttnNotfStat VARCHAR(3)
	             ,@AttnNotfClosType VARCHAR(3)
	             ,@AttnNotfClosIntr INT
	             ,@DlftStat VARCHAR(3)
	             ,@DebtClngStat VARCHAR(3)
	             ,@MostDebtClngAmnt BIGINT
	             ,@ExprDebtDay INT
                ,@TryValdSbmt VARCHAR(3)
                ,@DebtChckStat VARCHAR(3)
                ,@GateAttnStat VARCHAR(3)
                ,@GateCommPortName VARCHAR(30)
                ,@GateBandRate INT
                ,@GateTimeClos INT
                ,@GateEntrOpen VARCHAR(3)
                ,@GateExitOpen VARCHAR(3)
                ,@ExpnExtrStat VARCHAR(3)
                ,@ExpnCommPortName VARCHAR(30)
                ,@ExpnBandRate INT
                ,@RunQury VARCHAR(3)
                ,@AttnPrntStat VARCHAR(3)
                ,@SharMbspStat VARCHAR(3)
                ,@RunRbot VARCHAR(3)
                ,@ClerZero VARCHAR(3)
                ,@HldyCont INT;
	             
      	
	      SELECT  @BackUp = @X.query('//Settings').value('(Settings/@backup)[1]', 'BIT')
	             ,@BackupAppExit = @X.query('//Settings').value('(Settings/@backupappexit)[1]', 'BIT')
	             ,@BackupInTred = @X.query('//Settings').value('(Settings/@backupintred)[1]', 'BIT')
	             ,@BackupOptnPath = @X.query('//Settings').value('(Settings/@backupoptnpath)[1]', 'BIT')	       
	             ,@BackupOptnPathAdrs = @X.query('//Settings').value('(Settings/@backupoptnpathadrs)[1]', 'NVARCHAR(MAX)')
	             ,@BackupRootPath = @X.query('//Settings').value('(Settings/@backuprootpath)[1]', 'NVARCHAR(MAX)')
	             ,@ClubCode = @X.query('//Settings').value('(Settings/@clubcode)[1]', 'BIGINT')
	             ,@DresStat = @X.query('//Settings').value('(Settings/@dresstat)[1]', 'VARCHAR(3)')
	             ,@DresAuto = @X.query('//Settings').value('(Settings/@dresauto)[1]', 'VARCHAR(3)')
	             ,@MoreFighOneDres = @X.query('//Settings').value('(Settings/@morefighonedres)[1]', 'VARCHAR(3)')
	             ,@MoreAttnSesn = @X.query('//Settings').value('(Settings/@moreattnsesn)[1]', 'VARCHAR(3)')
	             ,@NotfStat = @X.query('//Settings').value('(Settings/@notfstat)[1]', 'VARCHAR(3)')
	             ,@NotfExpDay = @X.query('//Settings').value('(Settings/@notfexpday)[1]', 'INT')
	             ,@AttnSysmType = @X.query('//Settings').value('(Settings/@attnsysttype)[1]', 'VARCHAR(3)')
	             ,@CommPortName = @X.query('//Settings').value('(Settings/@commportname)[1]', 'VARCHAR(30)')
	             ,@BandRate = @X.query('//Settings').value('(Settings/@bandrate)[1]', 'INT')
	             ,@BarCodeDataType = @X.query('//Settings').value('(Settings/@barcodedatatype)[1]', 'VARCHAR(3)')
	             ,@Atn3EvntActnType = @X.query('//Settings').value('(Settings/@atn3evntactntype)[1]', 'VARCHAR(3)')
	             
	             ,@IPAddr = @X.query('//Settings').value('(Settings/@ipaddr)[1]', 'VARCHAR(15)')
	             ,@PortNumb = @X.query('//Settings').value('(Settings/@portnumb)[1]', 'INT')
	             ,@AttnCompConct = @X.query('//Settings').value('(Settings/@attncompconct)[1]', 'VARCHAR(30)')
	             ,@Atn1EvntActnType = @X.query('//Settings').value('(Settings/@atn1evntactntype)[1]', 'VARCHAR(3)')
	             
	             ,@IPAdr2 = @X.query('//Settings').value('(Settings/@ipadr2)[1]', 'VARCHAR(15)')
	             ,@PortNum2 = @X.query('//Settings').value('(Settings/@portnum2)[1]', 'INT')
	             ,@AttnCompCnc2 = @X.query('//Settings').value('(Settings/@attncompcnc2)[1]', 'VARCHAR(30)')
	             ,@Atn2EvntActnType = @X.query('//Settings').value('(Settings/@atn2evntactntype)[1]', 'VARCHAR(3)')
	             
	             ,@AttnNotfStat = @X.query('//Settings').value('(Settings/@attnnotfstat)[1]', 'VARCHAR(3)')
	             ,@AttnNotfClosType = @X.query('//Settings').value('(Settings/@attnnotfclostype)[1]', 'VARCHAR(3)')
	             ,@AttnNotfClosIntr = @X.query('//Settings').value('(Settings/@attnnotfclosintr)[1]', 'INT')
	             ,@DlftStat = @X.query('//Settings').value('(Settings/@dlftstat)[1]', 'VARCHAR(3)')
	             ,@DebtClngStat = @X.query('//Settings').value('(Settings/@debtclngstat)[1]', 'VARCHAR(3)')
	             ,@MostDebtClngAmnt = @X.query('//Settings').value('(Settings/@mostdebtclngamnt)[1]', 'BIGINT')
	             ,@ExprDebtDay = @X.query('//Settings').value('(Settings/@exprdebtday)[1]', 'INT')
	             ,@TryValdSbmt = @X.query('//Settings').value('(Settings/@tryvaldsbmt)[1]', 'VARCHAR(3)')
	             ,@DebtChckStat = @X.query('//Settings').value('(Settings/@debtchckstat)[1]', 'VARCHAR(3)')
	             
	             ,@GateAttnStat = @X.query('//Settings').value('(Settings/@gateattnstat)[1]', 'VARCHAR(3)')
	             ,@GateCommPortName = @X.query('//Settings').value('(Settings/@gatecommportname)[1]', 'VARCHAR(30)')
	             ,@GateBandRate = @X.query('//Settings').value('(Settings/@gatebandrate)[1]', 'INT')
	             ,@GateTimeClos = @X.query('//Settings').value('(Settings/@gatetimeclos)[1]', 'INT')
	             ,@GateEntrOpen = @X.query('//Settings').value('(Settings/@gateentropen)[1]', 'VARCHAR(3)')
	             ,@GateExitOpen = @X.query('//Settings').value('(Settings/@gateexitopen)[1]', 'VARCHAR(3)')
	             
	             ,@ExpnExtrStat = @X.query('//Settings').value('(Settings/@expnextrstat)[1]', 'VARCHAR(3)')
	             ,@ExpnCommPortName = @X.query('//Settings').value('(Settings/@expncommportname)[1]', 'VARCHAR(30)')
	             ,@ExpnBandRate = @X.query('//Settings').value('(Settings/@expnbandrate)[1]', 'INT')
	             
	             ,@RunQury = @X.query('//Settings').value('(Settings/@runqury)[1]', 'VARCHAR(3)')
	             ,@AttnPrntStat = @X.query('//Settings').value('(Settings/@attnprntstat)[1]', 'VARCHAR(3)')
	             ,@SharMbspStat = @X.query('//Settings').value('(Settings/@sharmbspstat)[1]', 'VARCHAR(3)')
	             ,@RunRbot = @X.query('//Settings').value('(Settings/@runrbot)[1]', 'VARCHAR(3)')
	             
	             ,@ClerZero = @X.query('//Settings').value('(Settings/@clerzero)[1]', 'VARCHAR(3)')
	             ,@HldyCont = @X.query('//Settings').value('(Settings/@hldycont)[1]', 'INT');
         
         IF NOT EXISTS(SELECT * FROM Settings WHERE CLUB_CODE = @ClubCode AND @ClubCode != 0)
            INSERT INTO Settings (CLUB_CODE) VALUES(@ClubCode);
         
         IF EXISTS(SELECT * FROM dbo.Settings WHERE DFLT_STAT = '002' AND @DlftStat = '002' AND CLUB_CODE != @ClubCode)
            SET @DlftStat = '001';
         
         IF @ClubCode = 0
            UPDATE Settings
               SET BACK_UP = 1
                  ,BACK_UP_APP_EXIT = 1
                  ,BACK_UP_IN_TRED = 1
                  ,BACK_UP_OPTN_PATH = 1
                  ,BACK_UP_OPTN_PATH_ADRS = COALESCE(@BackupOptnPathAdrs, 'D:\iData\Asre Andishe Project\Database Backup')
                  ,BACK_UP_ROOT_PATH = COALESCE(@BackupRootPath, 'C:\Backup');
         ELSE                     
            UPDATE Settings
               SET /*BACK_UP = COALESCE(@BackUp, 1)
                  ,BACK_UP_APP_EXIT = COALESCE(@BackupAppExit, 1)
                  ,BACK_UP_IN_TRED = COALESCE(@BackupInTred, 1)
                  ,BACK_UP_OPTN_PATH = COALESCE(@BackupOptnPath, 1)
                  ,BACK_UP_OPTN_PATH_ADRS = COALESCE(@BackupOptnPathAdrs, 'D:\iData\Asre Andishe Project\Database Backup')
                  ,BACK_UP_ROOT_PATH = COALESCE(@BackupRootPath, 'C:\Backup')*/
                   DRES_STAT = COALESCE(@DresStat, '002')
                  ,DRES_AUTO = COALESCE(@DresAuto, '002')
                  ,MORE_FIGH_ONE_DRES = COALESCE(@MoreFighOneDres, '001')
                  ,MORE_ATTN_SESN = COALESCE(@MoreAttnSesn, '002')
                  ,NOTF_STAT = COALESCE(@NotfStat, '002')
                  ,NOTF_EXP_DAY = COALESCE(@NotfExpDay, 3)
                  ,ATTN_SYST_TYPE = COALESCE(@AttnSysmType, '001')
                  ,COMM_PORT_NAME = COALESCE(@CommPortName, 'COM1')
                  ,BAND_RATE = COALESCE(@BandRate, 9600)
                  ,BAR_CODE_DATA_TYPE = COALESCE(@BarCodeDataType, '001')
                  ,ATN3_EVNT_ACTN_TYPE = @Atn3EvntActnType
                  
                  ,IP_ADDR = @IPAddr
                  ,PORT_NUMB = @PortNumb
                  ,ATTN_COMP_CONCT = @AttnCompConct
                  ,ATN1_EVNT_ACTN_TYPE = @Atn1EvntActnType
                  
                  ,IP_ADR2 = @IPAdr2
                  ,PORT_NUM2 = @PortNum2
                  ,ATTN_COMP_CNC2 = @AttnCompCnc2
                  ,ATN2_EVNT_ACTN_TYPE = @Atn2EvntActnType
                  
                  ,ATTN_NOTF_STAT = @AttnNotfStat
                  ,ATTN_NOTF_CLOS_TYPE = @AttnNotfClosType
                  ,ATTN_NOTF_CLOS_INTR = @AttnNotfClosIntr
                  ,DEBT_CLNG_STAT = @DebtClngStat
                  ,MOST_DEBT_CLNG_AMNT = @MostDebtClngAmnt
                  ,EXPR_DEBT_DAY = @ExprDebtDay
                  ,TRY_VALD_SBMT = @TryValdSbmt
                  ,DEBT_CHCK_STAT = @DebtChckStat
                  
                  ,GATE_ATTN_STAT = @GateAttnStat
                  ,GATE_COMM_PORT_NAME = @GateCommPortName
                  ,GATE_BAND_RATE = @GateBandRate
                  ,GATE_TIME_CLOS = @GateTimeClos
                  ,GATE_ENTR_OPEN = @GateEntrOpen
                  ,GATE_EXIT_OPEN = @GateExitOpen
                  
                  ,EXPN_EXTR_STAT = @ExpnExtrStat
                  ,EXPN_COMM_PORT_NAME = @ExpnCommPortName
                  ,EXPN_BAND_RATE = @ExpnBandRate
                  
                  ,RUN_QURY = @RunQury
                  ,ATTN_PRNT_STAT = @AttnPrntStat
                  ,SHAR_MBSP_STAT = @SharMbspStat
                  ,RUN_RBOT = @RunRbot
                  
                  ,HLDY_CONT = @HldyCont
                  ,CLER_ZERO = @ClerZero
             WHERE CLUB_CODE = @ClubCode;
      END;
      ELSE IF @ConfigType = '001' -- ADD_FGA_UREGN
      BEGIN
         SELECT @PrvnCode = @X.query('//FgaURegn').value('(FgaURegn/@prvncode)[1]', 'VARCHAR(3)')
               ,@RegnCode = @X.query('//FgaURegn').value('(FgaURegn/@regncode)[1]', 'VARCHAR(3)')
               ,@SysUser  = @X.query('//FgaURegn').value('(FgaURegn/@sysuser)[1]', 'VARCHAR(250)');
         IF LEN(@PrvnCode) <> 3 RAISERROR(N'استان مورد نظر را انتخاب کنید', 16, 1);
         IF LEN(@RegnCode) <> 3 RAISERROR(N'ناحیه مورد نظر را انتخاب کنید', 16, 1);
         IF LEN(@SysUser) = 0 RAISERROR(N'کاربر مورد نظر را انتخاب کنید', 16, 1);
         
         IF NOT EXISTS(SELECT * FROM V#URFGA WHERE REGN_PRVN_CODE = @PrvnCode AND REGN_CODE = @RegnCode AND SYS_USER = @SysUser)
         INSERT INTO User_Region_Fgac (FGA_CODE, REGN_PRVN_CNTY_CODE, REGN_PRVN_CODE, REGN_CODE, SYS_USER)
         VALUES                       (0, '001', @PrvnCode, @RegnCode, UPPER(@SysUser));
      END
      ELSE IF @ConfigType = '002' -- DEL_FGA_UREGN
      BEGIN
         SELECT @PrvnCode = @X.query('//FgaURegn').value('(FgaURegn/@prvncode)[1]', 'VARCHAR(3)')
               ,@RegnCode = @X.query('//FgaURegn').value('(FgaURegn/@regncode)[1]', 'VARCHAR(3)')
               ,@SysUser  = @X.query('//FgaURegn').value('(FgaURegn/@sysuser)[1]', 'VARCHAR(250)');
         IF LEN(@PrvnCode) <> 3 RAISERROR(N'استان مورد نظر را انتخاب کنید', 16, 1);
         IF LEN(@RegnCode) <> 3 RAISERROR(N'ناحیه مورد نظر را انتخاب کنید', 16, 1);
         IF LEN(@SysUser) = 0 RAISERROR(N'کاربر مورد نظر را انتخاب کنید', 16, 1);
         
         UPDATE User_Region_Fgac
            SET REC_STAT = '001'
               --,VALD_TYPE = '001'
          WHERE REGN_PRVN_CODE = @PrvnCode
            AND REGN_CODE = @RegnCode
            AND SYS_USER = @SysUser;
      END
      ELSE IF @ConfigType = '003' -- ADD_FGA_UCLUB
      BEGIN
         SELECT @MstrSysUser = @X.query('//FgaUClub').value('(FgaUClub/@mstrsysuser)[1]', 'VARCHAR(250)')
               ,@ClubCode = @X.query('//FgaUClub').value('(FgaUClub/@clubcode)[1]', 'BIGINT')
               ,@SysUser  = @X.query('//FgaUClub').value('(FgaUClub/@sysuser)[1]', 'VARCHAR(250)');
         IF @ClubCode = 0 RAISERROR(N'باشگاه مورد نظر را انتخاب کنید', 16, 1);
         IF LEN(@SysUser) = 0 RAISERROR(N'کاربر مورد نظر را انتخاب کنید', 16, 1);
         
         -- اگر کاربر ناحیه تعریف نشده باشد
         IF NOT EXISTS(SELECT * FROM dbo.V#URFGA ug, dbo.Club c WHERE c.REGN_PRVN_CNTY_CODE = ug.REGN_PRVN_CNTY_CODE AND c.REGN_PRVN_CODE = ug.REGN_PRVN_CODE AND c.REGN_CODE = ug.REGN_CODE AND SYS_USER = @SysUser)
         INSERT INTO dbo.User_Region_Fgac ( FGA_CODE , REGN_PRVN_CNTY_CODE , REGN_PRVN_CODE , REGN_CODE , SYS_USER , REC_STAT , VALD_TYPE )
         SELECT 0, REGN_PRVN_CNTY_CODE, REGN_PRVN_CODE, REGN_CODE, @SysUser, '002', '002'
           FROM dbo.Club
          WHERE CODE = @ClubCode;
         
         IF NOT EXISTS(SELECT * FROM V#UCFGA WHERE CLUB_CODE = @ClubCode AND SYS_USER = @SysUser)
         INSERT INTO User_Club_Fgac (FGA_CODE, CLUB_CODE, SYS_USER, MAST_SYS_USER)
         VALUES                     (0, @ClubCode, @SysUser, @MstrSysUser);
         
      END
      ELSE IF @ConfigType = '004' -- DEL_FGA_UCLUB
      BEGIN
         SELECT @MstrSysUser = @X.query('//FgaUClub').value('(FgaUClub/@mstrsysuser)[1]', 'VARCHAR(250)')
               ,@ClubCode = @X.query('//FgaUClub').value('(FgaUClub/@clubcode)[1]', 'BIGINT')
               ,@SysUser  = @X.query('//FgaUClub').value('(FgaUClub/@sysuser)[1]', 'VARCHAR(250)');
         IF @ClubCode = 0 RAISERROR(N'باشگاه مورد نظر را انتخاب کنید', 16, 1);
         IF LEN(@SysUser) = 0 RAISERROR(N'کاربر مورد نظر را انتخاب کنید', 16, 1);
         
         -- اگر کاربر ناحیه تعریف نشده باشد
         IF NOT EXISTS(SELECT * FROM dbo.V#URFGA ug, dbo.Club c WHERE c.REGN_PRVN_CNTY_CODE = ug.REGN_PRVN_CNTY_CODE AND c.REGN_PRVN_CODE = ug.REGN_PRVN_CODE AND c.REGN_CODE = ug.REGN_CODE AND SYS_USER = @SysUser)
         INSERT INTO dbo.User_Region_Fgac ( FGA_CODE , REGN_PRVN_CNTY_CODE , REGN_PRVN_CODE , REGN_CODE , SYS_USER , REC_STAT , VALD_TYPE )
         SELECT 0, REGN_PRVN_CNTY_CODE, REGN_PRVN_CODE, REGN_CODE, @SysUser, '002', '002'
           FROM dbo.Club
          WHERE CODE = @ClubCode;

         
         UPDATE User_Club_Fgac
            SET REC_STAT = '001'
               --,VALD_TYPE = '001'
          WHERE CLUB_CODE = @ClubCode
            AND SYS_USER = @SysUser
            AND REC_STAT = '002';
      END
      ELSE IF @ConfigType = '005' -- CLUB_METHOD
      BEGIN
		   DECLARE C$Del_Cbmt CURSOR FOR
			   SELECT rx.query('Club_Method').value('(Club_Method/@code)[1]', 'BIGINT')
		        FROM @X.nodes('//Delete') Dcb(rx);
		   
		   DECLARE @Cbmt_Code BIGINT;
		   DECLARE @VisitPrivilege BIT;
		   SET @VisitPrivilege = 0;
		   -------------------------- Delete Club_Method
		   OPEN C$Del_Cbmt;
		   FNFC$Del_Cbmt:
		   FETCH NEXT FROM C$Del_Cbmt INTO @Cbmt_Code;
		   
		   IF @@FETCH_STATUS <> 0
		      GOTO CDC$Del_Cbmt;
		   
		   IF @VisitPrivilege = 0
		   BEGIN
		      DECLARE @AP BIT
                   ,@AccessString VARCHAR(250);
            SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>46</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
            EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
            IF @AP = 0 
            BEGIN
               RAISERROR ( N'خطا - عدم دسترسی به ردیف 46 سطوح امینتی', -- Message text.
                        16, -- Severity.
                        1 -- State.
                        );
               RETURN;
            END
            SET @VisitPrivilege = 1;
         END
		   IF EXISTS(SELECT * FROM Fighter WHERE CBMT_CODE_DNRM = @Cbmt_Code) BEGIN RAISERROR(N'ساعت کلاسی دارای هنرجو می باشد', 16, 1)  END
		   IF EXISTS(SELECT * FROM Fighter_Public WHERE CBMT_CODE = @Cbmt_Code AND RECT_CODE = '004') BEGIN RAISERROR(N'ساعت کلاسی در اختیار سوابق هنرجویان می باشد', 16, 1)  END

		   DELETE Club_Method WHERE CODE = @Cbmt_Code;
		      
		   GOTO FNFC$Del_Cbmt;
		   CDC$Del_Cbmt:
		   CLOSE C$Del_Cbmt;
		   DEALLOCATE C$Del_Cbmt; 		   
		   ------------------------ End Delete
		   
		   DECLARE C$Ins_Cbmt CURSOR FOR
			   SELECT rx.query('Club_Method').value('(Club_Method/@clubcode)[1]', 'BIGINT')
			         ,rx.query('Club_Method').value('(Club_Method/@mtodcode)[1]', 'BIGINT')
			         ,rx.query('Club_Method').value('(Club_Method/@cochfileno)[1]', 'BIGINT')
			         ,rx.query('Club_Method').value('(Club_Method/@daytype)[1]', 'VARCHAR(3)')
			         ,rx.query('Club_Method').value('(Club_Method/@strttime)[1]', 'TIME(7)')
			         ,rx.query('Club_Method').value('(Club_Method/@endtime)[1]', 'TIME(7)')
			         ,rx.query('Club_Method').value('(Club_Method/@mtodstat)[1]', 'VARCHAR(3)')
			         ,rx.query('Club_Method').value('(Club_Method/@sextype)[1]', 'VARCHAR(3)')
			         ,rx.query('Club_Method').value('(Club_Method/@cbmtdesc)[1]', 'NVARCHAR(250)')
			         ,rx.query('Club_Method').value('(Club_Method/@dfltstat)[1]', 'VARCHAR(3)')
			         ,rx.query('Club_Method').value('(Club_Method/@cpctnumb)[1]', 'INT')
			         ,rx.query('Club_Method').value('(Club_Method/@cpctstat)[1]', 'VARCHAR(3)')
			         ,rx.query('Club_Method').value('(Club_Method/@cbmttime)[1]', 'INT')
			         ,rx.query('Club_Method').value('(Club_Method/@cbmttimestat)[1]', 'VARCHAR(3)')
			         ,rx.query('Club_Method').value('(Club_Method/@clastime)[1]', 'INT')
		        FROM @X.nodes('//Insert') Dcb(rx);
		   
		   DECLARE @MtodCode BIGINT
		          ,@CochFileNo BIGINT
		          ,@DayType  VARCHAR(3)
		          ,@StrtTime TIME(7)
		          ,@EndTime TIME(7)
		          ,@MtodStat VARCHAR(3)
		          ,@SexType VARCHAR(3)
		          ,@CbmtDesc NVARCHAR(250)
		          ,@DfltStat varchar(3)
		          ,@CpctNumb INT
		          ,@CpctStat VARCHAR(3)
		          ,@CbmtTime INT
		          ,@CbmtTimeStat VARCHAR(3)
		          ,@ClasTime INT;
		   SET @VisitPrivilege = 0;
		   -------------------------- Insert Club_Method
		   OPEN C$Ins_Cbmt;
		   FNFC$Ins_Cbmt:
		   FETCH NEXT FROM C$Ins_Cbmt INTO @ClubCode, @MtodCode, @CochFileNo, @DayType, @StrtTime, @EndTime, @MtodStat, @SexType, @CbmtDesc, @DfltStat, @CpctNumb, @CpctStat, @CbmtTime, @CbmtTimeStat, @ClasTime;
		   
		   IF @@FETCH_STATUS <> 0
		      GOTO CDC$Ins_Cbmt;
		   
		   IF @VisitPrivilege = 0
		   BEGIN
            SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>45</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
            EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
            IF @AP = 0 
            BEGIN
               RAISERROR ( N'خطا - عدم دسترسی به ردیف 45 سطوح امینتی', -- Message text.
                        16, -- Severity.
                        1 -- State.
                        );
               RETURN;
            END
            SET @VisitPrivilege = 1;
         END
		   
		   --IF EXISTS(SELECT * FROM Club_Method WHERE DAY_TYPE = @DayType AND STRT_TIME > @StrtTime AND END_TIME < @EndTime)
		   --   RAISERROR(N'ساعت کلاس وارد شده با سایر ساعت های کلاسی مربیان تداخل دارد', 16, 1);
		   
		   INSERT INTO Club_Method (CODE, CLUB_CODE, MTOD_CODE, COCH_FILE_NO, DAY_TYPE, STRT_TIME, END_TIME, MTOD_STAT, SEX_TYPE, CBMT_DESC, DFLT_STAT, CPCT_NUMB, CPCT_STAT, CBMT_TIME, CBMT_TIME_STAT, CLAS_TIME)
		   VALUES                  (dbo.GNRT_NVID_U()   , @ClubCode, @MtodCode, @CochFileNo , @DayType, @StrtTime, @EndTime, @MtodStat, @SexType, @CbmtDesc, @DfltStat, @CpctNumb, @CpctStat, @CbmtTime, @CbmtTimeStat, @ClasTime);
		      
		   GOTO FNFC$Ins_Cbmt;
		   CDC$Ins_Cbmt:
		   CLOSE C$Ins_Cbmt;
		   DEALLOCATE C$Ins_Cbmt; 
		   ------------------------ End Insert
		   
		   DECLARE C$Upd_Cbmt CURSOR FOR
			   SELECT rx.query('Club_Method').value('(Club_Method/@code)[1]', 'BIGINT') 
			         ,rx.query('Club_Method').value('(Club_Method/@clubcode)[1]', 'BIGINT')
			         ,rx.query('Club_Method').value('(Club_Method/@mtodcode)[1]', 'BIGINT')
			         ,rx.query('Club_Method').value('(Club_Method/@cochfileno)[1]', 'BIGINT')
			         ,rx.query('Club_Method').value('(Club_Method/@daytype)[1]', 'VARCHAR(3)')
			         ,rx.query('Club_Method').value('(Club_Method/@strttime)[1]', 'TIME(7)')
			         ,rx.query('Club_Method').value('(Club_Method/@endtime)[1]', 'TIME(7)')
			         ,rx.query('Club_Method').value('(Club_Method/@mtodstat)[1]', 'VARCHAR(3)')
			         ,rx.query('Club_Method').value('(Club_Method/@sextype)[1]', 'VARCHAR(3)')
			         ,rx.query('Club_Method').value('(Club_Method/@cbmtdesc)[1]', 'NVARCHAR(250)')
			         ,rx.query('Club_Method').value('(Club_Method/@dfltstat)[1]', 'VARCHAR(3)')
			         ,rx.query('Club_Method').value('(Club_Method/@cpctnumb)[1]', 'INT')
			         ,rx.query('Club_Method').value('(Club_Method/@cpctstat)[1]', 'VARCHAR(3)')
			         ,rx.query('Club_Method').value('(Club_Method/@cbmttime)[1]', 'INT')
			         ,rx.query('Club_Method').value('(Club_Method/@cbmttimestat)[1]', 'VARCHAR(3)')
			         ,rx.query('Club_Method').value('(Club_Method/@clastime)[1]', 'INT')
		        FROM @X.nodes('//Update') Dcb(rx);
		   
		   SET @VisitPrivilege = 0;
		   -------------------------- Insert Club_Method
		   OPEN C$Upd_Cbmt;
		   FNFC$Upd_Cbmt:
		   FETCH NEXT FROM C$Upd_Cbmt INTO @Cbmt_Code, @ClubCode, @MtodCode, @CochFileNo, @DayType, @StrtTime, @EndTime, @MtodStat,@SexType, @CbmtDesc, @DfltStat, @CpctNumb, @CpctStat, @CbmtTime, @CbmtTimeStat, @ClasTime;
		   
		   IF @@FETCH_STATUS <> 0
		      GOTO CDC$Upd_Cbmt;
		   
		   IF @VisitPrivilege = 0
		   BEGIN
            SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>46</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
            EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
            IF @AP = 0 
            BEGIN
               RAISERROR ( N'خطا - عدم دسترسی به ردیف 46 سطوح امینتی', -- Message text.
                        16, -- Severity.
                        1 -- State.
                        );
               RETURN;
            END
            SET @VisitPrivilege = 1;
         END
		   
		   --IF EXISTS(SELECT * FROM Club_Method WHERE CODE <> @Cbmt_Code AND DAY_TYPE = @DayType AND STRT_TIME > @StrtTime AND END_TIME < @EndTime)
		   --   RAISERROR(N'ساعت کلاس وارد شده با سایر ساعت های کلاسی مربیان تداخل دارد', 16, 1);
		   
		   UPDATE Club_Method
		      SET DAY_TYPE = @DayType
		         ,STRT_TIME = @StrtTime
		         ,END_TIME = @EndTime
		         ,MTOD_STAT = @MtodStat
		         ,CLUB_CODE = @ClubCode
		         ,MTOD_CODE = @MtodCode
		         ,COCH_FILE_NO = @CochFileNo
		         ,SEX_TYPE = @SexType
		         ,CBMT_DESC = @CbmtDesc
		         ,DFLT_STAT = @DfltStat
		         ,CPCT_NUMB = @CpctNumb
		         ,CPCT_STAT = @CpctStat
		         ,CBMT_TIME = @CbmtTime
		         ,CBMT_TIME_STAT = @CbmtTimeStat
		         ,CLAS_TIME = @ClasTime
		    WHERE CODE = @Cbmt_Code;
		   
		   MERGE dbo.Club_Method_Weekday T
		   USING (
		      SELECT r.query('.').value('(Club_Method_Weekday/@code)[1]', 'BIGINT') AS Code
		            ,r.query('.').value('(Club_Method_Weekday/@weekday)[1]', 'VARCHAR(3)') AS Weekday
		            ,r.query('.').value('(Club_Method_Weekday/@stat)[1]', 'VARCHAR(3)') AS Stat
		        FROM @X.nodes('//Club_Method_Weekday') cmw(r)		        
		   ) S
		   ON (T.Cbmt_Code = @Cbmt_Code AND T.Code = S.Code)
		   WHEN MATCHED THEN
		      UPDATE 
		         SET STAT = S.Stat;
		   
		      
		   GOTO FNFC$Upd_Cbmt;
		   CDC$Upd_Cbmt:
		   CLOSE C$Upd_Cbmt;
		   DEALLOCATE C$Upd_Cbmt; 
		   ------------------------ End Insert
      END
      ELSE IF @ConfigType = '006' -- CLUB
      BEGIN
		   DECLARE C$Del_Club CURSOR FOR
			   SELECT rx.query('Club').value('(Club/@code)[1]', 'BIGINT')
		        FROM @X.nodes('//Delete') Dcb(rx);
		   
		   --DECLARE @Club_Code BIGINT;
		   SET @VisitPrivilege = 0;
		   -------------------------- Delete Club_Method
		   OPEN C$Del_Club;
		   FNFC$Del_Club:
		   FETCH NEXT FROM C$Del_Club INTO @ClubCode;
		   
		   IF @@FETCH_STATUS <> 0
		      GOTO CDC$Del_Club;
		   
		   IF @VisitPrivilege = 0
		   BEGIN
            SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>44</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
            EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
            IF @AP = 0 
            BEGIN
               RAISERROR ( N'خطا - عدم دسترسی به ردیف 44 سطوح امینتی', -- Message text.
                        16, -- Severity.
                        1 -- State.
                        );
               RETURN;
            END
            SET @VisitPrivilege = 1;
         END
		   
		   IF EXISTS(SELECT * FROM Club_Method WHERE CLUB_CODE = @ClubCode) BEGIN RAISERROR(N'باشگاه دارای ساعت کلاسی می باشد', 16, 1)  END
		   IF EXISTS(SELECT * FROM Fighter WHERE CLUB_CODE_DNRM = @ClubCode) BEGIN RAISERROR(N'باشگاه دارای هنرجو می باشد', 16, 1)  END
		   IF EXISTS(SELECT * FROM Fighter_Public WHERE CLUB_CODE = @ClubCode AND RECT_CODE = '004') BEGIN RAISERROR(N'باشگاه، برای هنرجو دارای سابقه فعالیت می باشد', 16, 1)  END
		   IF EXISTS(SELECT * FROM User_Club_Fgac WHERE CLUB_CODE = @ClubCode AND REC_STAT = '002') BEGIN RAISERROR(N'باشگاه در اختیار حوزه دید کاربر می باشد', 16, 1)  END

		   DELETE Club WHERE CODE = @ClubCode;
		      
		   GOTO FNFC$Del_Club;
		   CDC$Del_Club:
		   CLOSE C$Del_Club;
		   DEALLOCATE C$Del_Club; 		   
		   ------------------------ End Delete
		   
		   DECLARE C$Ins_Club CURSOR FOR
			   SELECT rx.query('Club').value('(Club/@cntycode)[1]', 'VARCHAR(3)')
			         ,rx.query('Club').value('(Club/@prvncode)[1]', 'VARCHAR(3)')
			         ,rx.query('Club').value('(Club/@regncode)[1]', 'VARCHAR(3)')
			         ,rx.query('Club').value('(Club/@name)[1]', 'NVARCHAR(250)')
			         ,rx.query('Club').value('(Club/@postadrs)[1]', 'NVARCHAR(1000)')
			         ,rx.query('Club').value('(Club/@emaladrs)[1]', 'VARCHAR(250)')
			         ,rx.query('Club').value('(Club/@website)[1]', 'VARCHAR(500)')
			         ,rx.query('Club').value('(Club/@clubcode)[1]', 'BIGINT')
		        FROM @X.nodes('//Insert') Dcb(rx);
		   
		   DECLARE @CntyCode VARCHAR(3)
		          --,@PrvnCode VARCHAR(3)
		          --,@RegnCode VARCHAR(3)
		          ,@Name     NVARCHAR(250)
		          ,@PostAdrs NVARCHAR(1000)
		          ,@EmalAdrs VARCHAR(250)
		          ,@WebSite  VARCHAR(500);
		          --,@ClubCode BIGINT
		   SET @VisitPrivilege = 0;
		   -------------------------- Insert Club_Method
		   OPEN C$Ins_Club;
		   FNFC$Ins_Club:
		   FETCH NEXT FROM C$Ins_Club INTO @CntyCode, @PrvnCode, @RegnCode, @Name, @PostAdrs, @EmalAdrs, @WebSite, @ClubCode
		   
		   IF @@FETCH_STATUS <> 0
		      GOTO CDC$Ins_Club;
		   
		   IF @VisitPrivilege = 0
		   BEGIN
            SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>42</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
            EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
            IF @AP = 0 
            BEGIN
               RAISERROR ( N'خطا - عدم دسترسی به ردیف 42 سطوح امینتی', -- Message text.
                        16, -- Severity.
                        1 -- State.
                        );
               RETURN;
            END
            SET @VisitPrivilege = 1;
         END
         
         IF @Name IS NULL OR LEN(@Name) = 0 BEGIN RAISERROR(N'نام باشگاه وارد نشده', 16, 1); END
         
		   INSERT INTO Club (REGN_PRVN_CNTY_CODE, REGN_PRVN_CODE, REGN_CODE, NAME, POST_ADRS, EMAL_ADRS, WEB_SITE, CLUB_CODE)
		   VALUES           (@CntyCode          , @PrvnCode     , @RegnCode, @Name , @PostAdrs, @EmalAdrs, @WebSite, CASE WHEN @ClubCode IS NULL OR @ClubCode = 0 THEN NULL ELSE @ClubCode END);
		      
		   GOTO FNFC$Ins_Club;
		   CDC$Ins_Club:
		   CLOSE C$Ins_Club;
		   DEALLOCATE C$Ins_Club; 
		   ------------------------ End Insert
		   DECLARE @Code BIGINT;
		   
		   DECLARE C$Upd_Club CURSOR FOR
			   SELECT rx.query('Club').value('(Club/@cntycode)[1]', 'VARCHAR(3)')
			         ,rx.query('Club').value('(Club/@prvncode)[1]', 'VARCHAR(3)')
			         ,rx.query('Club').value('(Club/@regncode)[1]', 'VARCHAR(3)')
			         ,rx.query('Club').value('(Club/@code)[1]', 'BIGINT')
			         ,rx.query('Club').value('(Club/@name)[1]', 'NVARCHAR(250)')
			         ,rx.query('Club').value('(Club/@postadrs)[1]', 'NVARCHAR(1000)')
			         ,rx.query('Club').value('(Club/@emaladrs)[1]', 'VARCHAR(250)')
			         ,rx.query('Club').value('(Club/@website)[1]', 'VARCHAR(500)')
			         ,rx.query('Club').value('(Club/@clubcode)[1]', 'BIGINT')
		        FROM @X.nodes('//Update') Dcb(rx);
		   
		   SET @VisitPrivilege = 0;
		   -------------------------- Insert Club_Method
		   OPEN C$Upd_Club;
		   FNFC$Upd_Club:
		   FETCH NEXT FROM C$Upd_Club INTO @CntyCode, @PrvnCode, @RegnCode, @Code, @Name, @PostAdrs, @EmalAdrs, @WebSite, @ClubCode
		   
		   IF @@FETCH_STATUS <> 0
		      GOTO CDC$Upd_Club;
		   
		   IF @VisitPrivilege = 0
		   BEGIN
            SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>43</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
            EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
            IF @AP = 0 
            BEGIN
               RAISERROR ( N'خطا - عدم دسترسی به ردیف 43 سطوح امینتی', -- Message text.
                        16, -- Severity.
                        1 -- State.
                        );
               RETURN;
            END
            SET @VisitPrivilege = 1;
         END
		   
		   UPDATE Club
		      SET NAME = @Name
		         ,POST_ADRS = @PostAdrs
		         ,EMAL_ADRS = @EmalAdrs
		         ,WEB_SITE = @WebSite
		         ,CLUB_CODE = CASE WHEN @ClubCode IS NULL OR @ClubCode = 0 THEN NULL ELSE @ClubCode END
		    WHERE CODE = @Code;
		      
		   GOTO FNFC$Upd_Club;
		   CDC$Upd_Club:
		   CLOSE C$Upd_Club;
		   DEALLOCATE C$Upd_Club; 
		   ------------------------ End Insert
      END
      ELSE IF @ConfigType = '007'
      BEGIN
		   DECLARE C$Del_Region CURSOR FOR
			   SELECT rx.query('Region').value('(Region/@cntycode)[1]', 'VARCHAR(3)')
			         ,rx.query('Region').value('(Region/@prvncode)[1]', 'VARCHAR(3)')
			         ,rx.query('Region').value('(Region/@code)[1]', 'VARCHAR(3)')
		        FROM @X.nodes('//Delete') Dcb(rx);
		   
		   --DECLARE @Region_Code BIGINT;
		   SET @VisitPrivilege = 0;
		   -------------------------- Delete Region_Method
		   OPEN C$Del_Region;
		   FNFC$Del_Region:
		   FETCH NEXT FROM C$Del_Region INTO @CntyCode, @PrvnCode, @RegnCode;
		   
		   IF @@FETCH_STATUS <> 0
		      GOTO CDC$Del_Region;
		   
		   IF @VisitPrivilege = 0
		   BEGIN
            SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>36</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
            EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
            IF @AP = 0 
            BEGIN
               RAISERROR ( N'خطا - عدم دسترسی به ردیف 36 سطوح امینتی', -- Message text.
                        16, -- Severity.
                        1 -- State.
                        );
               RETURN;
            END
            SET @VisitPrivilege = 1;
         END
		   
		   DELETE Region WHERE PRVN_CNTY_CODE = @CntyCode AND PRVN_CODE = @PrvnCode AND CODE = @RegnCode;
		      
		   GOTO FNFC$Del_Region;
		   CDC$Del_Region:
		   CLOSE C$Del_Region;
		   DEALLOCATE C$Del_Region; 		   
		   ------------------------ End Delete
		   
		   DECLARE C$Ins_Region CURSOR FOR
			   SELECT rx.query('Region').value('(Region/@cntycode)[1]', 'VARCHAR(3)')
			         ,rx.query('Region').value('(Region/@prvncode)[1]', 'VARCHAR(3)')
			         ,rx.query('Region').value('(Region/@code)[1]', 'VARCHAR(3)')
			         ,rx.query('Region').value('(Region/@regncode)[1]', 'VARCHAR(3)')
			         ,rx.query('Region').value('(Region/@name)[1]', 'NVARCHAR(250)')
		        FROM @X.nodes('//Insert') Dcb(rx);
		   
         DECLARE @RefRegnCode VARCHAR(3);
		   SET @VisitPrivilege = 0;
		   -------------------------- Insert Region_Method
		   OPEN C$Ins_Region;
		   FNFC$Ins_Region:
		   FETCH NEXT FROM C$Ins_Region INTO @CntyCode, @PrvnCode, @RegnCode, @RefRegnCode, @Name;
		   
		   IF @@FETCH_STATUS <> 0
		      GOTO CDC$Ins_Region;
		   
		   IF @VisitPrivilege = 0
		   BEGIN
            SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>34</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
            EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
            IF @AP = 0 
            BEGIN
               RAISERROR ( N'خطا - عدم دسترسی به ردیف 34 سطوح امینتی', -- Message text.
                        16, -- Severity.
                        1 -- State.
                        );
               RETURN;
            END
            SET @VisitPrivilege = 1;
         END
         
         IF @Name IS NULL OR LEN(@Name) = 0 BEGIN RAISERROR(N'نام ناحیه وارد نشده', 16, 1); END
         IF LEN(@RegnCode) = 0 BEGIN RAISERROR(N'کد ناحیه وارد نشده', 16, 1); END
         IF EXISTS(SELECT * FROM Region WHERE PRVN_CNTY_CODE = @CntyCode AND PRVN_CODE = @PrvnCode AND CODE = @RegnCode) BEGIN RAISERROR(N'کد ناحیه تکراری می باشد', 16, 1) END
         
		   INSERT INTO Region (PRVN_CNTY_CODE, PRVN_CODE, CODE, REGN_CODE, NAME)
		   VALUES             (@CntyCode     , @PrvnCode, @RegnCode, CASE WHEN @RefRegnCode IS NULL THEN @RegnCode ELSE @RefRegnCode END, @Name);
		      
		   GOTO FNFC$Ins_Region;
		   CDC$Ins_Region:
		   CLOSE C$Ins_Region;
		   DEALLOCATE C$Ins_Region; 
		   ------------------------ End Insert
		   DECLARE C$Upd_Region CURSOR FOR
			   SELECT rx.query('Region').value('(Region/@cntycode)[1]', 'VARCHAR(3)')
			         ,rx.query('Region').value('(Region/@prvncode)[1]', 'VARCHAR(3)')
			         ,rx.query('Region').value('(Region/@code)[1]', 'VARCHAR(3)')
			         ,rx.query('Region').value('(Region/@regncode)[1]', 'VARCHAR(3)')
			         ,rx.query('Region').value('(Region/@name)[1]', 'NVARCHAR(250)')
		        FROM @X.nodes('//Update') Dcb(rx);
		   
		   SET @VisitPrivilege = 0;
		   -------------------------- Insert Region_Method
		   OPEN C$Upd_Region;
		   FNFC$Upd_Region:
		   FETCH NEXT FROM C$Upd_Region INTO @CntyCode, @PrvnCode, @RegnCode, @RefRegnCode, @Name;
		   
		   IF @@FETCH_STATUS <> 0
		      GOTO CDC$Upd_Region;
		   
		   IF @VisitPrivilege = 0
		   BEGIN
            SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>35</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
            EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
            IF @AP = 0 
            BEGIN
               RAISERROR ( N'خطا - عدم دسترسی به ردیف 35 سطوح امینتی', -- Message text.
                        16, -- Severity.
                        1 -- State.
                        );
               RETURN;
            END
            SET @VisitPrivilege = 1;
         END
		   
		   UPDATE Region
		      SET NAME = @Name
		         ,REGN_CODE = CASE WHEN @RefRegnCode IS NULL THEN @RegnCode ELSE @RefRegnCode END
		    WHERE PRVN_CNTY_CODE = @CntyCode 
		      AND PRVN_CODE = @PrvnCode
		      AND CODE = @RegnCode;
		      
		   GOTO FNFC$Upd_Region;
		   CDC$Upd_Region:
		   CLOSE C$Upd_Region;
		   DEALLOCATE C$Upd_Region; 
		   ------------------------ End Insert
      END
      ELSE IF @ConfigType = '008'
      BEGIN
		   DECLARE C$Del_Province CURSOR FOR
			   SELECT rx.query('Province').value('(Province/@cntycode)[1]', 'VARCHAR(3)')
			         ,rx.query('Province').value('(Province/@code)[1]', 'VARCHAR(3)')
		        FROM @X.nodes('//Delete') Dcb(rx);
		   
		   --DECLARE @Province_Code BIGINT;
		   SET @VisitPrivilege = 0;
		   -------------------------- Delete Province_Method
		   OPEN C$Del_Province;
		   FNFC$Del_Province:
		   FETCH NEXT FROM C$Del_Province INTO @CntyCode, @PrvnCode;
		   
		   IF @@FETCH_STATUS <> 0
		      GOTO CDC$Del_Province;
		   
		   IF @VisitPrivilege = 0
		   BEGIN
            SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>33</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
            EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
            IF @AP = 0 
            BEGIN
               RAISERROR ( N'خطا - عدم دسترسی به ردیف 33 سطوح امینتی', -- Message text.
                        16, -- Severity.
                        1 -- State.
                        );
               RETURN;
            END
            SET @VisitPrivilege = 1;
         END
		   
		   DELETE Province WHERE CNTY_CODE = @CntyCode  AND CODE = @PrvnCode;
		      
		   GOTO FNFC$Del_Province;
		   CDC$Del_Province:
		   CLOSE C$Del_Province;
		   DEALLOCATE C$Del_Province; 		   
		   ------------------------ End Delete
		   
		   DECLARE C$Ins_Province CURSOR FOR
			   SELECT rx.query('Province').value('(Province/@cntycode)[1]', 'VARCHAR(3)')
			         ,rx.query('Province').value('(Province/@code)[1]', 'VARCHAR(3)')
			         ,rx.query('Province').value('(Province/@name)[1]', 'NVARCHAR(250)')
		        FROM @X.nodes('//Insert') Dcb(rx);
		   
		   SET @VisitPrivilege = 0;
		   -------------------------- Insert Province_Method
		   OPEN C$Ins_Province;
		   FNFC$Ins_Province:
		   FETCH NEXT FROM C$Ins_Province INTO @CntyCode, @PrvnCode, @Name;
		   
		   IF @@FETCH_STATUS <> 0
		      GOTO CDC$Ins_Province;
		   
		   IF @VisitPrivilege = 0
		   BEGIN
            SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>31</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
            EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
            IF @AP = 0 
            BEGIN
               RAISERROR ( N'خطا - عدم دسترسی به ردیف 31 سطوح امینتی', -- Message text.
                        16, -- Severity.
                        1 -- State.
                        );
               RETURN;
            END
            SET @VisitPrivilege = 1;
         END
         
         IF @Name IS NULL OR LEN(@Name) = 0 BEGIN RAISERROR(N'نام استان وارد نشده', 16, 1); END
         IF LEN(@PrvnCode) = 0 BEGIN RAISERROR(N'کد استان وارد نشده', 16, 1); END
         IF EXISTS(SELECT * FROM Province WHERE CNTY_CODE = @CntyCode AND CODE = @PrvnCode) BEGIN RAISERROR(N'کد استان تکراری می باشد', 16, 1) END
         
		   INSERT INTO Province (CNTY_CODE, CODE, NAME)
		   VALUES               (@CntyCode, @PrvnCode, @Name);
		      
		   GOTO FNFC$Ins_Province;
		   CDC$Ins_Province:
		   CLOSE C$Ins_Province;
		   DEALLOCATE C$Ins_Province; 
		   ------------------------ End Insert
		   DECLARE C$Upd_Province CURSOR FOR
			   SELECT rx.query('Province').value('(Province/@cntycode)[1]', 'VARCHAR(3)')
			         ,rx.query('Province').value('(Province/@code)[1]', 'VARCHAR(3)')
			         ,rx.query('Province').value('(Province/@name)[1]', 'NVARCHAR(250)')
		        FROM @X.nodes('//Update') Dcb(rx);
		   
		   SET @VisitPrivilege = 0;
		   -------------------------- Insert Province_Method
		   OPEN C$Upd_Province;
		   FNFC$Upd_Province:
		   FETCH NEXT FROM C$Upd_Province INTO @CntyCode, @PrvnCode, @Name;
		   
		   IF @@FETCH_STATUS <> 0
		      GOTO CDC$Upd_Province;
		   
		   IF @VisitPrivilege = 0
		   BEGIN
            SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>32</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
            EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
            IF @AP = 0 
            BEGIN
               RAISERROR ( N'خطا - عدم دسترسی به ردیف 32 سطوح امینتی', -- Message text.
                        16, -- Severity.
                        1 -- State.
                        );
               RETURN;
            END
            SET @VisitPrivilege = 1;
         END
		   
		   UPDATE Province
		      SET NAME = @Name
		    WHERE CNTY_CODE = @CntyCode 		      
		      AND CODE = @PrvnCode;
		      
		   GOTO FNFC$Upd_Province;
		   CDC$Upd_Province:
		   CLOSE C$Upd_Province;
		   DEALLOCATE C$Upd_Province; 
		   ------------------------ End Insert
      END
      ELSE IF @ConfigType = '009'
      BEGIN
		   DECLARE C$Del_Country CURSOR FOR
			   SELECT rx.query('Country').value('(Country/@code)[1]', 'VARCHAR(3)')
		        FROM @X.nodes('//Delete') Dcb(rx);
		   
		   --DECLARE @Country_Code BIGINT;
		   SET @VisitPrivilege = 0;
		   -------------------------- Delete Country_Method
		   OPEN C$Del_Country;
		   FNFC$Del_Country:
		   FETCH NEXT FROM C$Del_Country INTO @CntyCode;
		   
		   IF @@FETCH_STATUS <> 0
		      GOTO CDC$Del_Country;
		   
		   IF @VisitPrivilege = 0
		   BEGIN
            SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>30</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
            EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
            IF @AP = 0 
            BEGIN
               RAISERROR ( N'خطا - عدم دسترسی به ردیف 30 سطوح امینتی', -- Message text.
                        16, -- Severity.
                        1 -- State.
                        );
               RETURN;
            END
            SET @VisitPrivilege = 1;
         END
		   
		   DELETE Country WHERE CODE = @CntyCode;
		      
		   GOTO FNFC$Del_Country;
		   CDC$Del_Country:
		   CLOSE C$Del_Country;
		   DEALLOCATE C$Del_Country; 		   
		   ------------------------ End Delete
		   
		   DECLARE C$Ins_Country CURSOR FOR
			   SELECT rx.query('Country').value('(Country/@code)[1]', 'VARCHAR(3)')
			         ,rx.query('Country').value('(Country/@name)[1]', 'NVARCHAR(250)')
		        FROM @X.nodes('//Insert') Dcb(rx);
		   
		   SET @VisitPrivilege = 0;
		   -------------------------- Insert Country_Method
		   OPEN C$Ins_Country;
		   FNFC$Ins_Country:
		   FETCH NEXT FROM C$Ins_Country INTO @CntyCode, @Name;
		   
		   IF @@FETCH_STATUS <> 0
		      GOTO CDC$Ins_Country;
		   
		   IF @VisitPrivilege = 0
		   BEGIN
            SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>28</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
            EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
            IF @AP = 0 
            BEGIN
               RAISERROR ( N'خطا - عدم دسترسی به ردیف 28 سطوح امینتی', -- Message text.
                        16, -- Severity.
                        1 -- State.
                        );
               RETURN;
            END
            SET @VisitPrivilege = 1;
         END
         
         IF @Name IS NULL OR LEN(@Name) = 0 BEGIN RAISERROR(N'نام کشور وارد نشده', 16, 1); END
         IF LEN(@CntyCode) = 0 BEGIN RAISERROR(N'کد کشور وارد نشده', 16, 1); END
         IF EXISTS(SELECT * FROM Country WHERE CODE = @PrvnCode) BEGIN RAISERROR(N'کد کشور تکراری می باشد', 16, 1) END
         
		   INSERT INTO Country (CODE, NAME)
		   VALUES              (@CntyCode, @Name);
		      
		   GOTO FNFC$Ins_Country;
		   CDC$Ins_Country:
		   CLOSE C$Ins_Country;
		   DEALLOCATE C$Ins_Country; 
		   ------------------------ End Insert
		   DECLARE C$Upd_Country CURSOR FOR
			   SELECT rx.query('Country').value('(Country/@code)[1]', 'VARCHAR(3)')
			         ,rx.query('Country').value('(Country/@name)[1]', 'NVARCHAR(250)')
		        FROM @X.nodes('//Update') Dcb(rx);
		   
		   SET @VisitPrivilege = 0;
		   -------------------------- Insert Country_Method
		   OPEN C$Upd_Country;
		   FNFC$Upd_Country:
		   FETCH NEXT FROM C$Upd_Country INTO @CntyCode, @Name;
		   
		   IF @@FETCH_STATUS <> 0
		      GOTO CDC$Upd_Country;
		   
		   IF @VisitPrivilege = 0
		   BEGIN
            SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>29</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
            EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
            IF @AP = 0 
            BEGIN
               RAISERROR ( N'خطا - عدم دسترسی به ردیف 29 سطوح امینتی', -- Message text.
                        16, -- Severity.
                        1 -- State.
                        );
               RETURN;
            END
            SET @VisitPrivilege = 1;
         END
		   
		   UPDATE Country
		      SET NAME = @Name
		    WHERE CODE = @CntyCode;
		      
		   GOTO FNFC$Upd_Country;
		   CDC$Upd_Country:
		   CLOSE C$Upd_Country;
		   DEALLOCATE C$Upd_Country; 
		   ------------------------ End Insert
      END
      ELSE IF @ConfigType = '010'
      BEGIN
		   DECLARE C$Del_Expense_Item CURSOR FOR
			   SELECT rx.query('Expense_Item').value('(Expense_Item/@code)[1]', 'BIGINT')
		        FROM @X.nodes('//Delete') Dcb(rx);
		   
		   SET @VisitPrivilege = 0;
		   -------------------------- Delete Expense_Item_Method
		   OPEN C$Del_Expense_Item;
		   FNFC$Del_Expense_Item:
		   FETCH NEXT FROM C$Del_Expense_Item INTO @Code;
		   
		   IF @@FETCH_STATUS <> 0
		      GOTO CDC$Del_Expense_Item;
		   
		   IF @VisitPrivilege = 0
		   BEGIN
            SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>40</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
            EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
            IF @AP = 0 
            BEGIN
               RAISERROR ( N'خطا - عدم دسترسی به ردیف 40 سطوح امینتی', -- Message text.
                        16, -- Severity.
                        1 -- State.
                        );
               RETURN;
            END
            SET @VisitPrivilege = 1;
         END
		   
		   DELETE Expense_Item WHERE CODE = @Code;
		      
		   GOTO FNFC$Del_Expense_Item;
		   CDC$Del_Expense_Item:
		   CLOSE C$Del_Expense_Item;
		   DEALLOCATE C$Del_Expense_Item; 		   
		   ------------------------ End Delete
		   
		   DECLARE C$Ins_Expense_Item CURSOR FOR
			   SELECT rx.query('Expense_Item').value('(Expense_Item/@type)[1]', 'VARCHAR(3)')
			         ,rx.query('Expense_Item').value('(Expense_Item/@epitdesc)[1]', 'NVARCHAR(250)')
			         ,rx.query('Expense_Item').value('(Expense_Item/@autognrt)[1]', 'VARCHAR(3)')
			         ,rx.query('Expense_Item').value('(Expense_Item/@rqtpcode)[1]', 'VARCHAR(3)')
			         ,rx.query('Expense_Item').value('(Expense_Item/@rqttcode)[1]', 'VARCHAR(3)')
		        FROM @X.nodes('//Insert') Dcb(rx);
		   DECLARE @RqtpCode VARCHAR(3)
		          ,@RqttCode VARCHAR(3)
		          ,@AutoGnrt VARCHAR(3);
		   SET @VisitPrivilege = 0;
		   -------------------------- Insert Expense_Item_Method
		   OPEN C$Ins_Expense_Item;
		   FNFC$Ins_Expense_Item:
		   FETCH NEXT FROM C$Ins_Expense_Item INTO @Type, @Name, @AutoGnrt, @RqtpCode, @RqttCode;
		   
		   IF @@FETCH_STATUS <> 0
		      GOTO CDC$Ins_Expense_Item;
		   
		   IF @VisitPrivilege = 0
		   BEGIN
            SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>38</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
            EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
            IF @AP = 0 
            BEGIN
               RAISERROR ( N'خطا - عدم دسترسی به ردیف 38 سطوح امینتی', -- Message text.
                        16, -- Severity.
                        1 -- State.
                        );
               RETURN;
            END
            SET @VisitPrivilege = 1;
         END
         
         IF @Name IS NULL OR LEN(@Name) = 0 BEGIN RAISERROR(N'نام آیتم هزینه وارد نشده', 16, 1); END
         IF LEN(@Type) = 0 BEGIN RAISERROR(N'نوع آیتم هزینه وارد نشده', 16, 1); END
         IF LEN(@RqtpCode) = 0 BEGIN SET @RqtpCode = NULL; END
         IF LEN(@RqttCode) = 0 BEGIN SET @RqttCode = NULL; END

		   INSERT INTO Expense_Item (TYPE, EPIT_DESC, AUTO_GNRT, RQTP_CODE, RQTT_CODE)
		   VALUES                   (@Type, @Name, @AutoGnrt, @RqtpCode, @RqttCode);
		      
		   GOTO FNFC$Ins_Expense_Item;
		   CDC$Ins_Expense_Item:
		   CLOSE C$Ins_Expense_Item;
		   DEALLOCATE C$Ins_Expense_Item; 
		   ------------------------ End Insert
		   DECLARE C$Upd_Expense_Item CURSOR FOR
			   SELECT rx.query('Expense_Item').value('(Expense_Item/@code)[1]', 'BIGINT')
			         ,rx.query('Expense_Item').value('(Expense_Item/@type)[1]', 'VARCHAR(3)')			         
			         ,rx.query('Expense_Item').value('(Expense_Item/@epitdesc)[1]', 'NVARCHAR(250)')
			         ,rx.query('Expense_Item').value('(Expense_Item/@autognrt)[1]', 'VARCHAR(3)')
			         ,rx.query('Expense_Item').value('(Expense_Item/@rqtpcode)[1]', 'VARCHAR(3)')
			         ,rx.query('Expense_Item').value('(Expense_Item/@rqttcode)[1]', 'VARCHAR(3)')
		        FROM @X.nodes('//Update') Dcb(rx);
		   
		   SET @VisitPrivilege = 0;
		   -------------------------- Insert Expense_Item_Method
		   OPEN C$Upd_Expense_Item;
		   FNFC$Upd_Expense_Item:
		   FETCH NEXT FROM C$Upd_Expense_Item INTO @Code, @Type, @Name, @AutoGnrt, @RqtpCode, @RqttCode;
		   
		   IF @@FETCH_STATUS <> 0
		      GOTO CDC$Upd_Expense_Item;
		   
		   IF @VisitPrivilege = 0
		   BEGIN
            SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>39</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
            EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
            IF @AP = 0 
            BEGIN
               RAISERROR ( N'خطا - عدم دسترسی به ردیف 39 سطوح امینتی', -- Message text.
                        16, -- Severity.
                        1 -- State.
                        );
               RETURN;
            END
            SET @VisitPrivilege = 1;
         END
         
         IF LEN(@RqtpCode) = 0 BEGIN SET @RqtpCode = NULL; END
         IF LEN(@RqttCode) = 0 BEGIN SET @RqttCode = NULL; END
		   
		   UPDATE Expense_Item
		      SET EPIT_DESC = @Name
		         ,TYPE = @Type
		         ,AUTO_GNRT = @AutoGnrt
		         ,RQTP_CODE = @RqtpCode
		         ,RQTT_CODE = @RqttCode
		    WHERE CODE = @Code;
		      
		   GOTO FNFC$Upd_Expense_Item;
		   CDC$Upd_Expense_Item:
		   CLOSE C$Upd_Expense_Item;
		   DEALLOCATE C$Upd_Expense_Item; 
		   ------------------------ End Insert
      END
      ELSE IF @ConfigType = '011'
      BEGIN
		   DECLARE C$Del_Cash CURSOR FOR
			   SELECT rx.query('Cash').value('(Cash/@code)[1]', 'BIGINT')
		        FROM @X.nodes('//Delete') Dcb(rx);
		   
		   SET @VisitPrivilege = 0;
		   -------------------------- Delete Cash_Method
		   OPEN C$Del_Cash;
		   FNFC$Del_Cash:
		   FETCH NEXT FROM C$Del_Cash INTO @Code;
		   
		   IF @@FETCH_STATUS <> 0
		      GOTO CDC$Del_Cash;
		   
		   IF @VisitPrivilege = 0
		   BEGIN
            SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>143</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
            EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
            IF @AP = 0 
            BEGIN
               RAISERROR ( N'خطا - عدم دسترسی به ردیف 143 سطوح امینتی', -- Message text.
                        16, -- Severity.
                        1 -- State.
                        );
               RETURN;
            END
            SET @VisitPrivilege = 1;
         END
		   
		   DELETE Cash WHERE CODE = @Code;
		      
		   GOTO FNFC$Del_Cash;
		   CDC$Del_Cash:
		   CLOSE C$Del_Cash;
		   DEALLOCATE C$Del_Cash; 		   
		   ------------------------ End Delete
		   
		   DECLARE C$Ins_Cash CURSOR FOR
			   SELECT rx.query('Cash').value('(Cash/@name)[1]', 'NVARCHAR(250)')
			         ,rx.query('Cash').value('(Cash/@bankname)[1]', 'NVARCHAR(250)')
			         ,rx.query('Cash').value('(Cash/@bankbrnccode)[1]', 'VARCHAR(50)')
			         ,rx.query('Cash').value('(Cash/@bankacntnumb)[1]', 'VARCHAR(50)')
			         ,rx.query('Cash').value('(Cash/@shbaacnt)[1]', 'VARCHAR(26)')
			         ,rx.query('Cash').value('(Cash/@cardnumb)[1]', 'VARCHAR(19)')
			         ,rx.query('Cash').value('(Cash/@type)[1]', 'VARCHAR(3)')
			         ,rx.query('Cash').value('(Cash/@cashstat)[1]', 'VARCHAR(3)')
		        FROM @X.nodes('//Insert') Dcb(rx);
		   DECLARE @BankName NVARCHAR(250)
		          ,@BankBrncCode VARCHAR(50)
		          ,@BankAcntNumb VARCHAR(50)
		          ,@ShbaAcnt     VARCHAR(26)
		          ,@CardNumb     VARCHAR(19)
		          ,@CashStat     VARCHAR(3);
		          
		   SET @VisitPrivilege = 0;
		   -------------------------- Insert Cash_Method
		   OPEN C$Ins_Cash;
		   FNFC$Ins_Cash:
		   FETCH NEXT FROM C$Ins_Cash INTO @Name, @BankName, @BankBrncCode, @BankAcntNumb, @ShbaAcnt, @CardNumb, @Type, @CashStat;
		   
		   IF @@FETCH_STATUS <> 0
		      GOTO CDC$Ins_Cash;
		   
		   IF @VisitPrivilege = 0
		   BEGIN
            SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>141</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
            EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
            IF @AP = 0 
            BEGIN
               RAISERROR ( N'خطا - عدم دسترسی به ردیف 141 سطوح امینتی', -- Message text.
                        16, -- Severity.
                        1 -- State.
                        );
               RETURN;
            END
            SET @VisitPrivilege = 1;
         END
         
		   INSERT INTO Cash (NAME, BANK_NAME, BANK_BRNC_CODE, BANK_ACNT_NUMB, SHBA_ACNT, CARD_NUMB, TYPE, CASH_STAT)
		   VALUES           (@Name, @BankName, @BankBrncCode, @BankAcntNumb, @ShbaAcnt, @CardNumb, @Type, @CashStat);
		      
		   GOTO FNFC$Ins_Cash;
		   CDC$Ins_Cash:
		   CLOSE C$Ins_Cash;
		   DEALLOCATE C$Ins_Cash; 
		   ------------------------ End Insert
		   DECLARE C$Upd_Cash CURSOR FOR
			   SELECT rx.query('Cash').value('(Cash/@code)[1]', 'BIGINT')
			         ,rx.query('Cash').value('(Cash/@name)[1]', 'NVARCHAR(250)')
			         ,rx.query('Cash').value('(Cash/@bankname)[1]', 'NVARCHAR(250)')
			         ,rx.query('Cash').value('(Cash/@bankbrnccode)[1]', 'VARCHAR(50)')
			         ,rx.query('Cash').value('(Cash/@bankacntnumb)[1]', 'VARCHAR(50)')
			         ,rx.query('Cash').value('(Cash/@shbaacnt)[1]', 'VARCHAR(26)')
			         ,rx.query('Cash').value('(Cash/@cardnumb)[1]', 'VARCHAR(19)')
			         ,rx.query('Cash').value('(Cash/@type)[1]', 'VARCHAR(3)')
			         ,rx.query('Cash').value('(Cash/@cashstat)[1]', 'VARCHAR(3)')
		        FROM @X.nodes('//Update') Dcb(rx);
		   
		   SET @VisitPrivilege = 0;
		   -------------------------- Insert Cash_Method
		   OPEN C$Upd_Cash;
		   FNFC$Upd_Cash:
		   FETCH NEXT FROM C$Upd_Cash INTO @Code, @Name, @BankName, @BankBrncCode, @BankAcntNumb, @ShbaAcnt, @CardNumb, @Type, @CashStat;
		   
		   IF @@FETCH_STATUS <> 0
		      GOTO CDC$Upd_Cash;
		   
		   IF @VisitPrivilege = 0
		   BEGIN
            SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>142</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
            EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
            IF @AP = 0 
            BEGIN
               RAISERROR ( N'خطا - عدم دسترسی به ردیف 142 سطوح امینتی', -- Message text.
                        16, -- Severity.
                        1 -- State.
                        );
               RETURN;
            END
            SET @VisitPrivilege = 1;
         END
		   
		   UPDATE Cash
		      SET BANK_NAME = @BankName
		         ,BANK_BRNC_CODE = @BankBrncCode
		         ,BANK_ACNT_NUMB = @BankAcntNumb
		         ,SHBA_ACNT = @ShbaAcnt
		         ,CARD_NUMB = @CardNumb
		         ,TYPE = @Type
		         ,CASH_STAT = @CashStat
		    WHERE CODE = @Code;
		      
		   GOTO FNFC$Upd_Cash;
		   CDC$Upd_Cash:
		   CLOSE C$Upd_Cash;
		   DEALLOCATE C$Upd_Cash; 
		   ------------------------ End Insert
      END
      ELSE IF @ConfigType = '012'
      BEGIN
		   DECLARE C$Del_Modual_Report CURSOR FOR
			   SELECT rx.query('Modual_Report').value('(Modual_Report/@code)[1]', 'BIGINT')
		        FROM @X.nodes('//Delete') Dcb(rx);
		   
		   SET @VisitPrivilege = 0;
		   -------------------------- Delete Modual_Report_Method
		   OPEN C$Del_Modual_Report;
		   FNFC$Del_Modual_Report:
		   FETCH NEXT FROM C$Del_Modual_Report INTO @Code;
		   
		   IF @@FETCH_STATUS <> 0
		      GOTO CDC$Del_Modual_Report;
		   
		   IF @VisitPrivilege = 0
		   BEGIN
            SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>146</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
            EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
            IF @AP = 0 
            BEGIN
               RAISERROR ( N'خطا - عدم دسترسی به ردیف 146 سطوح امینتی', -- Message text.
                        16, -- Severity.
                        1 -- State.
                        );
               RETURN;
            END
            SET @VisitPrivilege = 1;
         END
		   
		   DELETE Modual_Report WHERE CODE = @Code;
		      
		   GOTO FNFC$Del_Modual_Report;
		   CDC$Del_Modual_Report:
		   CLOSE C$Del_Modual_Report;
		   DEALLOCATE C$Del_Modual_Report; 		   
		   ------------------------ End Delete
		   
		   DECLARE C$Ins_Modual_Report CURSOR FOR
			   SELECT rx.query('Modual_Report').value('(Modual_Report/@mdulname)[1]', 'VARCHAR(11)')
			         ,rx.query('Modual_Report').value('(Modual_Report/@mduldesc)[1]', 'NVARCHAR(200)')
			         ,rx.query('Modual_Report').value('(Modual_Report/@sectname)[1]', 'VARCHAR(11)')
			         ,rx.query('Modual_Report').value('(Modual_Report/@sectdesc)[1]', 'NVARCHAR(200)')
			         ,rx.query('Modual_Report').value('(Modual_Report/@rprtdesc)[1]', 'NVARCHAR(200)')
			         ,rx.query('Modual_Report').value('(Modual_Report/@rprtpath)[1]', 'VARCHAR(MAX)')
			         ,rx.query('Modual_Report').value('(Modual_Report/@showprvw)[1]', 'VARCHAR(3)')
			         ,rx.query('Modual_Report').value('(Modual_Report/@dflt)[1]', 'VARCHAR(3)')
			         ,rx.query('Modual_Report').value('(Modual_Report/@prntaftrpay)[1]', 'VARCHAR(3)')
			         ,rx.query('Modual_Report').value('(Modual_Report/@stat)[1]', 'VARCHAR(3)')
		        FROM @X.nodes('//Insert') Dcb(rx);
		   DECLARE @MdulName VARCHAR(11)
		          ,@MdulDesc NVARCHAR(200)
		          ,@SectName VARCHAR(11)
		          ,@SectDesc NVARCHAR(200)
		          ,@RprtDesc NVARCHAR(200)
		          ,@RprtPath VARCHAR(MAX)
		          ,@ShowPrvw VARCHAR(3)
		          ,@Dflt     VARCHAR(3)
		          ,@PrntAftrPay VARCHAR(3)
		          ,@Stat     VARCHAR(3);
		          
		   SET @VisitPrivilege = 0;
		   -------------------------- Insert Modual_Report_Method
		   OPEN C$Ins_Modual_Report;
		   FNFC$Ins_Modual_Report:
		   FETCH NEXT FROM C$Ins_Modual_Report INTO @MdulName, @MdulDesc, @SectName, @SectDesc, @RprtDesc, @RprtPath, @ShowPrvw, @Dflt, @PrntAftrPay, @Stat;
		   
		   IF @@FETCH_STATUS <> 0
		      GOTO CDC$Ins_Modual_Report;
		   
		   IF @VisitPrivilege = 0
		   BEGIN
            SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>144</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
            EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
            IF @AP = 0 
            BEGIN
               RAISERROR ( N'خطا - عدم دسترسی به ردیف 144 سطوح امینتی', -- Message text.
                        16, -- Severity.
                        1 -- State.
                        );
               RETURN;
            END
            SET @VisitPrivilege = 1;
         END
         
         --IF LEN(@MdulName) < 10 RAISERROR(N'نام فرم باید 10 کاراکتر باشد', 16, 1)
         IF LEN(@MdulDesc) = 0 RAISERROR(N'برای توضیحات چاپ فرم چیزی وارد نشده', 16, 1)
         IF LEN(@RprtPath) = 0 RAISERROR(N'برای فایل چاپ مسیر فایل مشخص نشده', 16, 1)
         IF LEN(@RprtDesc) = 0 SET @RprtDesc = @MdulDesc;
         IF LEN(@ShowPrvw) = 0 SET @ShowPrvw = '002'
         IF LEN(@Dflt) = 0 SET @Dflt = '001'
         IF LEN(@PrntAftrPay) = 0 SET @PrntAftrPay = '001'
         IF LEN(@Stat) = 0 SET @Stat = '002'
         
		   INSERT INTO Modual_Report (CODE, MDUL_NAME, MDUL_DESC, SECT_NAME, SECT_DESC, RPRT_DESC, RPRT_PATH, SHOW_PRVW, DFLT, PRNT_AFTR_PAY, STAT)
		   VALUES                    (0, @MdulName, @MdulDesc, @SectName, @SectDesc, @RprtDesc, @RprtPath, @ShowPrvw, @Dflt, @PrntAftrPay, @Stat);
		      
		   GOTO FNFC$Ins_Modual_Report;
		   CDC$Ins_Modual_Report:
		   CLOSE C$Ins_Modual_Report;
		   DEALLOCATE C$Ins_Modual_Report; 
		   ------------------------ End Insert
		   DECLARE C$Upd_Modual_Report CURSOR FOR
			   SELECT rx.query('Modual_Report').value('(Modual_Report/@code)[1]', 'BIGINT')
			         ,rx.query('Modual_Report').value('(Modual_Report/@mdulname)[1]', 'VARCHAR(11)')
			         ,rx.query('Modual_Report').value('(Modual_Report/@mduldesc)[1]', 'NVARCHAR(200)')
			         ,rx.query('Modual_Report').value('(Modual_Report/@sectname)[1]', 'VARCHAR(11)')
			         ,rx.query('Modual_Report').value('(Modual_Report/@sectdesc)[1]', 'NVARCHAR(200)')
			         ,rx.query('Modual_Report').value('(Modual_Report/@rprtdesc)[1]', 'NVARCHAR(200)')
			         ,rx.query('Modual_Report').value('(Modual_Report/@rprtpath)[1]', 'VARCHAR(MAX)')
			         ,rx.query('Modual_Report').value('(Modual_Report/@showprvw)[1]', 'VARCHAR(3)')
			         ,rx.query('Modual_Report').value('(Modual_Report/@dflt)[1]', 'VARCHAR(3)')
			         ,rx.query('Modual_Report').value('(Modual_Report/@prntaftrpay)[1]', 'VARCHAR(3)')
			         ,rx.query('Modual_Report').value('(Modual_Report/@stat)[1]', 'VARCHAR(3)')
		        FROM @X.nodes('//Update') Dcb(rx);
		   
		   SET @VisitPrivilege = 0;
		   -------------------------- Insert Modual_Report_Method
		   OPEN C$Upd_Modual_Report;
		   FNFC$Upd_Modual_Report:
		   FETCH NEXT FROM C$Upd_Modual_Report INTO @Code, @MdulName, @MdulDesc, @SectName, @SectDesc, @RprtDesc, @RprtPath, @ShowPrvw, @Dflt, @PrntAftrPay, @Stat;
		   
		   IF @@FETCH_STATUS <> 0
		      GOTO CDC$Upd_Modual_Report;
		   
		   IF @VisitPrivilege = 0
		   BEGIN
            SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>145</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
            EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
            IF @AP = 0 
            BEGIN
               RAISERROR ( N'خطا - عدم دسترسی به ردیف 145 سطوح امینتی', -- Message text.
                        16, -- Severity.
                        1 -- State.
                        );
               RETURN;
            END
            SET @VisitPrivilege = 1;
         END

         --IF LEN(@MdulName) <> 10 RAISERROR(N'نام فرم باید 10 کاراکتر باشد', 16, 1)
         IF LEN(@MdulDesc) = 0 RAISERROR(N'برای توضیحات چاپ فرم چیزی وارد نشده', 16, 1)
         IF LEN(@RprtPath) = 0 RAISERROR(N'برای فایل چاپ مسیر فایل مشخص نشده', 16, 1)
         IF LEN(@RprtDesc) = 0 SET @RprtDesc = @MdulDesc;
         IF LEN(@ShowPrvw) = 0 SET @ShowPrvw = '002'
         IF LEN(@Dflt) = 0 SET @Dflt = '001'
         IF LEN(@PrntAftrPay) = 0 SET @PrntAftrPay = '001'
         IF LEN(@Stat) = 0 SET @Stat = '002'
		   
		   UPDATE Modual_Report
		      SET MDUL_DESC = @MdulDesc
		         --,SECT_NAME = @SectName
		         ,SECT_DESC = @SectDesc
		         ,RPRT_DESC = @RprtDesc
		         ,RPRT_PATH = @RprtPath
		         ,SHOW_PRVW = @ShowPrvw
		         ,DFLT = @Dflt
		         ,PRNT_AFTR_PAY = @PrntAftrPay
		         ,STAT = @Stat
		    WHERE CODE = @Code;
		      
		   GOTO FNFC$Upd_Modual_Report;
		   CDC$Upd_Modual_Report:
		   CLOSE C$Upd_Modual_Report;
		   DEALLOCATE C$Upd_Modual_Report; 
		   ------------------------ End Insert
      END
      ELSE IF @ConfigType = '013'      
      BEGIN
		   DECLARE C$Del_Fga_URqrq CURSOR FOR
			   SELECT rx.query('Fga_URqrq').value('(Fga_URqrq/@code)[1]', 'BIGINT')
		        FROM @X.nodes('//Delete') Dcb(rx);
		   
		   SET @VisitPrivilege = 0;
		   -------------------------- Delete Fga_URqrq_Method
		   OPEN C$Del_Fga_URqrq;
		   FNFC$Del_Fga_URqrq:
		   FETCH NEXT FROM C$Del_Fga_URqrq INTO @Code;
		   
		   IF @@FETCH_STATUS <> 0
		      GOTO CDC$Del_Fga_URqrq;
		   
		   IF @VisitPrivilege = 0
		   BEGIN
            SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>150</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
            EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
            IF @AP = 0 
            BEGIN
               RAISERROR ( N'خطا - عدم دسترسی به ردیف 150 سطوح امینتی', -- Message text.
                        16, -- Severity.
                        1 -- State.
                        );
               RETURN;
            END
            SET @VisitPrivilege = 1;
         END
		   
		   UPDATE User_Request_Requester_Fgac 
		      SET REC_STAT = '001'
		    WHERE FGA_CODE = @Code;
		      
		   GOTO FNFC$Del_Fga_URqrq;
		   CDC$Del_Fga_URqrq:
		   CLOSE C$Del_Fga_URqrq;
		   DEALLOCATE C$Del_Fga_URqrq; 		   
		   ------------------------ End Delete
		   
		   DECLARE C$Ins_Fga_URqrq CURSOR FOR
			   SELECT rx.query('Fga_URqrq').value('(Fga_URqrq/@sysuser)[1]', 'VARCHAR(250)')
			         ,rx.query('Fga_URqrq').value('(Fga_URqrq/@rqtpcode)[1]', 'VARCHAR(3)')
			         ,rx.query('Fga_URqrq').value('(Fga_URqrq/@rqttcode)[1]', 'VARCHAR(3)')
		        FROM @X.nodes('//Insert') Dcb(rx);
		          
		   SET @VisitPrivilege = 0;
		   -------------------------- Insert Fga_URqrq_Method
		   OPEN C$Ins_Fga_URqrq;
		   FNFC$Ins_Fga_URqrq:
		   FETCH NEXT FROM C$Ins_Fga_URqrq INTO @SysUser, @RqtpCode, @RqttCode;
		   
		   IF @@FETCH_STATUS <> 0
		      GOTO CDC$Ins_Fga_URqrq;
		   
		   IF @VisitPrivilege = 0
		   BEGIN
            SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>149</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
            EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
            IF @AP = 0 
            BEGIN
               RAISERROR ( N'خطا - عدم دسترسی به ردیف 149 سطوح امینتی', -- Message text.
                        16, -- Severity.
                        1 -- State.
                        );
               RETURN;
            END
            SET @VisitPrivilege = 1;
         END
         
         IF LEN(@SysUser) = 0 RAISERROR(N'نام کاربر وارد نشده', 16, 1)
         IF LEN(@RqtpCode) = 0 RAISERROR(N'نوع درخواست وارد نشده', 16, 1)
         IF LEN(@RqttCode) = 0 RAISERROR(N'نوع قرارداد متقاضی وارد نشده', 16, 1)
         
		   INSERT INTO User_Request_Requester_Fgac (FGA_CODE, SYS_USER, RQTP_CODE, RQTT_CODE)
		   VALUES                                  (0, @SysUser, @RqtpCode, @RqttCode);
		      
		   GOTO FNFC$Ins_Fga_URqrq;
		   CDC$Ins_Fga_URqrq:
		   CLOSE C$Ins_Fga_URqrq;
		   DEALLOCATE C$Ins_Fga_URqrq; 
		   ------------------------ End Insert
      END
      ELSE IF @ConfigType = '014'
      BEGIN
		   DECLARE C$Del_Dresser CURSOR FOR
			   SELECT rx.query('Dresser').value('(Dresser/@code)[1]', 'BIGINT')
		        FROM @X.nodes('//Delete') Dcb(rx);
		   
		   SET @VisitPrivilege = 0;
		   -------------------------- Delete Dresser_Method
		   OPEN C$Del_Dresser;
		   FNFC$Del_Dresser:
		   FETCH NEXT FROM C$Del_Dresser INTO @Code;
		   
		   IF @@FETCH_STATUS <> 0
		      GOTO CDC$Del_Dresser;
		   
		   IF @VisitPrivilege = 0
		   BEGIN
            SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>157</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
            EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
            IF @AP = 0 
            BEGIN
               RAISERROR ( N'خطا - عدم دسترسی به ردیف 157 سطوح امینتی', -- Message text.
                        16, -- Severity.
                        1 -- State.
                        );
               RETURN;
            END
            SET @VisitPrivilege = 1;
         END
		   
		   DELETE Dresser WHERE CODE = @Code;
		      
		   GOTO FNFC$Del_Dresser;
		   CDC$Del_Dresser:
		   CLOSE C$Del_Dresser;
		   DEALLOCATE C$Del_Dresser; 		   
		   ------------------------ End Delete
		   
		   DECLARE C$Ins_Dresser CURSOR FOR
			   SELECT rx.query('Dresser').value('(Dresser/@clubcode)[1]', 'BIGINT')
			         ,rx.query('Dresser').value('(Dresser/@dresnumb)[1]', 'INT')
			         ,rx.query('Dresser').value('(Dresser/@desc)[1]', 'NVARCHAR(100)')
		        FROM @X.nodes('//Insert') Dcb(rx);
		   DECLARE @DresNumb INT
		          ,@Desc NVARCHAR(100)
		          ,@RecStat VARCHAR(3);
		          
		   SET @VisitPrivilege = 0;
		   -------------------------- Insert Dresser_Method
		   OPEN C$Ins_Dresser;
		   FNFC$Ins_Dresser:
		   FETCH NEXT FROM C$Ins_Dresser INTO @ClubCode, @DresNumb, @Desc;
		   
		   IF @@FETCH_STATUS <> 0
		      GOTO CDC$Ins_Dresser;
		   
		   IF @VisitPrivilege = 0
		   BEGIN
            SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>155</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
            EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
            IF @AP = 0 
            BEGIN
               RAISERROR ( N'خطا - عدم دسترسی به ردیف 155 سطوح امینتی', -- Message text.
                        16, -- Severity.
                        1 -- State.
                        );
               RETURN;
            END
            SET @VisitPrivilege = 1;
         END
         
		   INSERT INTO Dresser (CODE, CLUB_CODE, DRES_NUMB, [DESC])
		   VALUES              (dbo.GNRT_NVID_U(), @ClubCode, @DresNumb, @Desc);
		      
		   GOTO FNFC$Ins_Dresser;
		   CDC$Ins_Dresser:
		   CLOSE C$Ins_Dresser;
		   DEALLOCATE C$Ins_Dresser; 
		   ------------------------ End Insert
		   DECLARE C$Upd_Dresser CURSOR FOR
			   SELECT rx.query('Dresser').value('(Dresser/@code)[1]', 'BIGINT')
			         ,rx.query('Dresser').value('(Dresser/@dresnumb)[1]', 'INT')
			         ,rx.query('Dresser').value('(Dresser/@desc)[1]', 'NVARCHAR(100)')
			         ,rx.query('Dresser').value('(Dresser/@recstat)[1]', 'VARCHAR(3)')
		        FROM @X.nodes('//Update') Dcb(rx);
		   
		   SET @VisitPrivilege = 0;
		   -------------------------- Insert Dresser_Method
		   OPEN C$Upd_Dresser;
		   FNFC$Upd_Dresser:
		   FETCH NEXT FROM C$Upd_Dresser INTO @Code, @DresNumb, @Desc, @RecStat;
		   
		   IF @@FETCH_STATUS <> 0
		      GOTO CDC$Upd_Dresser;
		   
		   IF @VisitPrivilege = 0
		   BEGIN
            SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>156</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
            EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
            IF @AP = 0 
            BEGIN
               RAISERROR ( N'خطا - عدم دسترسی به ردیف 156 سطوح امینتی', -- Message text.
                        16, -- Severity.
                        1 -- State.
                        );
               RETURN;
            END
            SET @VisitPrivilege = 1;
         END

		   UPDATE Dresser
		      SET DRES_NUMB = @DresNumb
		         ,[DESC] = @Desc
		         ,REC_STAT = @RecStat
		    WHERE CODE = @Code;
		      
		   GOTO FNFC$Upd_Dresser;
		   CDC$Upd_Dresser:
		   CLOSE C$Upd_Dresser;
		   DEALLOCATE C$Upd_Dresser; 
		   ------------------------ End Insert
      END
      
      COMMIT TRAN STNG_SAVE_P_TRAN;
   END TRY
   BEGIN CATCH
      IF (SELECT CURSOR_STATUS('local','C$Del_Cbmt')) >= -1
      BEGIN
        IF (SELECT CURSOR_STATUS('local','C$Del_Cbmt')) > -1
         BEGIN
          CLOSE C$Del_Cbmt
         END
       DEALLOCATE C$Del_Cbmt
      END      
      IF (SELECT CURSOR_STATUS('local','C$Ins_Cbmt')) >= -1
      BEGIN
        IF (SELECT CURSOR_STATUS('local','C$Ins_Cbmt')) > -1
         BEGIN
          CLOSE C$Ins_Cbmt;
         END
       DEALLOCATE C$Ins_Cbmt;
      END
      IF (SELECT CURSOR_STATUS('local','C$Upd_Cbmt')) >= -1
      BEGIN
        IF (SELECT CURSOR_STATUS('local','C$Upd_Cbmt')) > -1
         BEGIN
          CLOSE C$Upd_Cbmt;
         END
       DEALLOCATE C$Upd_Cbmt;
      END
      IF (SELECT CURSOR_STATUS('local','C$Del_Club')) >= -1
      BEGIN
        IF (SELECT CURSOR_STATUS('local','C$Del_Club')) > -1
         BEGIN
          CLOSE C$Del_Club
         END
       DEALLOCATE C$Del_Club
      END      
      IF (SELECT CURSOR_STATUS('local','C$Ins_Club')) >= -1
      BEGIN
        IF (SELECT CURSOR_STATUS('local','C$Ins_Club')) > -1
         BEGIN
          CLOSE C$Ins_Club;
         END
       DEALLOCATE C$Ins_Club;
      END
      IF (SELECT CURSOR_STATUS('local','C$Upd_Club')) >= -1
      BEGIN
        IF (SELECT CURSOR_STATUS('local','C$Upd_Club')) > -1
         BEGIN
          CLOSE C$Upd_Club;
         END
       DEALLOCATE C$Upd_Club;
      END
      IF (SELECT CURSOR_STATUS('local','C$Del_Region')) >= -1
      BEGIN
        IF (SELECT CURSOR_STATUS('local','C$Del_Region')) > -1
         BEGIN
          CLOSE C$Del_Region
         END
       DEALLOCATE C$Del_Region
      END      
      IF (SELECT CURSOR_STATUS('local','C$Ins_Region')) >= -1
      BEGIN
        IF (SELECT CURSOR_STATUS('local','C$Ins_Region')) > -1
         BEGIN
          CLOSE C$Ins_Region;
         END
       DEALLOCATE C$Ins_Region;
      END
      IF (SELECT CURSOR_STATUS('local','C$Upd_Region')) >= -1
      BEGIN
        IF (SELECT CURSOR_STATUS('local','C$Upd_Region')) > -1
         BEGIN
          CLOSE C$Upd_Region;
         END
       DEALLOCATE C$Upd_Region;
      END
      IF (SELECT CURSOR_STATUS('local','C$Del_Province')) >= -1
      BEGIN
        IF (SELECT CURSOR_STATUS('local','C$Del_Province')) > -1
         BEGIN
          CLOSE C$Del_Province
         END
       DEALLOCATE C$Del_Province
      END      
      IF (SELECT CURSOR_STATUS('local','C$Ins_Province')) >= -1
      BEGIN
        IF (SELECT CURSOR_STATUS('local','C$Ins_Province')) > -1
         BEGIN
          CLOSE C$Ins_Province;
         END
       DEALLOCATE C$Ins_Province;
      END
      IF (SELECT CURSOR_STATUS('local','C$Upd_Province')) >= -1
      BEGIN
        IF (SELECT CURSOR_STATUS('local','C$Upd_Province')) > -1
         BEGIN
          CLOSE C$Upd_Province;
         END
       DEALLOCATE C$Upd_Province;
      END
      IF (SELECT CURSOR_STATUS('local','C$Del_Country')) >= -1
      BEGIN
        IF (SELECT CURSOR_STATUS('local','C$Del_Country')) > -1
         BEGIN
          CLOSE C$Del_Country
         END
       DEALLOCATE C$Del_Country
      END      
      IF (SELECT CURSOR_STATUS('local','C$Ins_Country')) >= -1
      BEGIN
        IF (SELECT CURSOR_STATUS('local','C$Ins_Country')) > -1
         BEGIN
          CLOSE C$Ins_Country;
         END
       DEALLOCATE C$Ins_Country;
      END
      IF (SELECT CURSOR_STATUS('local','C$Upd_Country')) >= -1
      BEGIN
        IF (SELECT CURSOR_STATUS('local','C$Upd_Country')) > -1
         BEGIN
          CLOSE C$Upd_Country;
         END
       DEALLOCATE C$Upd_Country;
      END      
      IF (SELECT CURSOR_STATUS('local','C$Del_Expense_Item')) >= -1
      BEGIN
        IF (SELECT CURSOR_STATUS('local','C$Del_Expense_Item')) > -1
         BEGIN
          CLOSE C$Del_Expense_Item
         END
       DEALLOCATE C$Del_Expense_Item
      END      
      IF (SELECT CURSOR_STATUS('local','C$Ins_Expense_Item')) >= -1
      BEGIN
        IF (SELECT CURSOR_STATUS('local','C$Ins_Expense_Item')) > -1
         BEGIN
          CLOSE C$Ins_Expense_Item;
         END
       DEALLOCATE C$Ins_Expense_Item;
      END
      IF (SELECT CURSOR_STATUS('local','C$Upd_Expense_Item')) >= -1
      BEGIN
        IF (SELECT CURSOR_STATUS('local','C$Upd_Expense_Item')) > -1
         BEGIN
          CLOSE C$Upd_Expense_Item;
         END
       DEALLOCATE C$Upd_Expense_Item;
      END      
      IF (SELECT CURSOR_STATUS('local','C$Del_Cash')) >= -1
      BEGIN
        IF (SELECT CURSOR_STATUS('local','C$Del_Cash')) > -1
         BEGIN
          CLOSE C$Del_Cash
         END
       DEALLOCATE C$Del_Cash
      END      
      IF (SELECT CURSOR_STATUS('local','C$Ins_Cash')) >= -1
      BEGIN
        IF (SELECT CURSOR_STATUS('local','C$Ins_Cash')) > -1
         BEGIN
          CLOSE C$Ins_Cash;
         END
       DEALLOCATE C$Ins_Cash;
      END
      IF (SELECT CURSOR_STATUS('local','C$Upd_Cash')) >= -1
      BEGIN
        IF (SELECT CURSOR_STATUS('local','C$Upd_Cash')) > -1
         BEGIN
          CLOSE C$Upd_Cash;
         END
       DEALLOCATE C$Upd_Cash;
      END 
      IF (SELECT CURSOR_STATUS('local','C$Del_Modual_Report')) >= -1
      BEGIN
        IF (SELECT CURSOR_STATUS('local','C$Del_Modual_Report')) > -1
         BEGIN
          CLOSE C$Del_Modual_Report
         END
       DEALLOCATE C$Del_Modual_Report
      END      
      IF (SELECT CURSOR_STATUS('local','C$Ins_Modual_Report')) >= -1
      BEGIN
        IF (SELECT CURSOR_STATUS('local','C$Ins_Modual_Report')) > -1
         BEGIN
          CLOSE C$Ins_Modual_Report;
         END
       DEALLOCATE C$Ins_Modual_Report;
      END
      IF (SELECT CURSOR_STATUS('local','C$Upd_Modual_Report')) >= -1
      BEGIN
        IF (SELECT CURSOR_STATUS('local','C$Upd_Modual_Report')) > -1
         BEGIN
          CLOSE C$Upd_Modual_Report;
         END
       DEALLOCATE C$Upd_Modual_Report;
      END 
      IF (SELECT CURSOR_STATUS('local','C$Del_Fga_URqrq')) >= -1
      BEGIN
        IF (SELECT CURSOR_STATUS('local','C$Del_Fga_URqrq')) > -1
         BEGIN
          CLOSE C$Del_Fga_URqrq
         END
       DEALLOCATE C$Del_Fga_URqrq
      END      
      IF (SELECT CURSOR_STATUS('local','C$Ins_Fga_URqrq')) >= -1
      BEGIN
        IF (SELECT CURSOR_STATUS('local','C$Ins_Fga_URqrq')) > -1
         BEGIN
          CLOSE C$Ins_Fga_URqrq;
         END
       DEALLOCATE C$Ins_Fga_URqrq;
      END
      IF (SELECT CURSOR_STATUS('local','C$Del_Dresser')) >= -1
      BEGIN
        IF (SELECT CURSOR_STATUS('local','C$Del_Dresser')) > -1
         BEGIN
          CLOSE C$Del_Dresser
         END
       DEALLOCATE C$Del_Dresser
      END      
      IF (SELECT CURSOR_STATUS('local','C$Ins_Dresser')) >= -1
      BEGIN
        IF (SELECT CURSOR_STATUS('local','C$Ins_Dresser')) > -1
         BEGIN
          CLOSE C$Ins_Dresser;
         END
       DEALLOCATE C$Ins_Dresser;
      END
      IF (SELECT CURSOR_STATUS('local','C$Upd_Dresser')) >= -1
      BEGIN
        IF (SELECT CURSOR_STATUS('local','C$Upd_Dresser')) > -1
         BEGIN
          CLOSE C$Upd_Dresser;
         END
       DEALLOCATE C$Upd_Dresser;
      END 

      SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN STNG_SAVE_P_TRAN;
   END CATCH
   
END
GO

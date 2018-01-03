SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[ADM_TSAV_F]
	-- Add the parameters for the stored procedure here
	@X XML
AS
BEGIN
   /*RAISERROR(N'گوه خوردی', 16, 1);
   RETURN;*/
   
   DECLARE @AP BIT
          ,@AccessString VARCHAR(250);
   SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>68</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 68 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END

   SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>69</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 69 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   
   SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>70</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 70 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END

	DECLARE @ErrorMessage NVARCHAR(MAX);
	BEGIN TRAN T$ADM_TSAV_F;
	BEGIN TRY
	   DECLARE @Rqid     BIGINT
	          ,@OrgnRqid BIGINT
	          ,@FileNo   BIGINT
	          ,@PrvnCode VARCHAR(3)
	          ,@RegnCode VARCHAR(3);   	
	          
	   SELECT @Rqid     = @X.query('//Request').value('(Request/@rqid)[1]'    , 'BIGINT')
	         ,@OrgnRqid = @X.query('//Request').value('(Request/@rqid)[1]'    , 'BIGINT')
	         ,@PrvnCode = @X.query('//Request').value('(Request/@prvncode)[1]', 'VARCHAR(3)')
	         ,@RegnCode = @X.query('//Request').value('(Request/@regncode)[1]', 'VARCHAR(3)');
	         
      SELECT @FileNo = File_No, @PrvnCode = REGN_PRVN_CODE, @RegnCode = REGN_CODE
        FROM Fighter
       WHERE RQST_RQID = @Rqid;
      
      UPDATE Payment_Detail
         SET PAY_STAT = '002'
            ,RCPT_MTOD = @x.query('//Payment_Detail[@code=sql:column("Code")]').value('(Payment_Detail/@rcptmtod)[1]', 'VARCHAR(3)')
       WHERE PYMT_RQST_RQID = @Rqid
         AND @x.query('//Payment').value('(Payment/@setondebt)[1]', 'BIT') = 0;
      
      DECLARE @DiseCode BIGINT
             ,@MtodCode BIGINT
             ,@CtgyCode BIGINT
             ,@ClubCode BIGINT
             ,@FrstName NVARCHAR(250)
             ,@LastName NVARCHAR(250)
             ,@FathName NVARCHAR(250)
             ,@SexType  VARCHAR(3)
             ,@NatlCode VARCHAR(10)
             ,@BrthDate DATE
             ,@CellPhon VARCHAR(11)
             ,@TellPhon VARCHAR(11)
             ,@CochDeg  VARCHAR(3)
             ,@GudgDeg  VARCHAR(3)
             ,@GlobCode VARCHAR(20)
             ,@Type     VARCHAR(3)
             ,@PostAdrs NVARCHAR(1000)
             ,@EmalAdrs NVARCHAR(250)
             ,@InsrNumb VARCHAR(10)
             ,@InsrDate DATE
             ,@EducDeg VARCHAR(3)
             ,@CochFileNo BIGINT
             ,@CbmtCode BIGINT
             ,@DayType VARCHAR(3)
             ,@AttnTime TIME(7)
             ,@CochCrtfDate DATE
             ,@CalcExpnType VARCHAR(3)
             ,@ActvTag VARCHAR(3)
             ,@BlodGrop VARCHAR(3)
             ,@FngrPrnt VARCHAR(20)
             ,@SuntBuntDeptOrgnCode VARCHAR(2)
             ,@SuntBuntDeptCode VARCHAR(2)
             ,@SuntBuntCode VARCHAR(2)
             ,@SuntCode VARCHAR(4)
             ,@CordX REAL
             ,@CordY REAL
             ,@MostDebtClng BIGINT
             ,@ServNo NVARCHAR(50)
             ,@BrthPlac NVARCHAR(100)
             ,@IssuPLac NVARCHAR(100)
             ,@FathWork NVARCHAR(150)
             ,@HistDesc NVARCHAR(500)
             ,@IntrFileNo BIGINT
             ,@CntrCode BIGINT;
             

      SELECT @DiseCode     = P.DISE_CODE
            ,@MtodCode     = P.MTOD_CODE
            ,@CtgyCode     = P.CTGY_CODE
            ,@ClubCode     = P.CLUB_CODE
            ,@FrstName     = P.FRST_NAME
            ,@LastName     = P.LAST_NAME
            ,@FathName     = P.FATH_NAME
            ,@SexType      = P.SEX_TYPE
            ,@NatlCode     = P.NATL_CODE
            ,@BrthDate     = P.BRTH_DATE
            ,@CellPhon     = P.CELL_PHON
            ,@TellPhon     = P.TELL_PHON
            ,@CochDeg      = P.COCH_DEG
            ,@GudgDeg      = P.GUDG_DEG
            ,@GlobCode     = P.GLOB_CODE
            ,@Type         = CASE P.TYPE WHEN '004' THEN '001' ELSE P.TYPE END
            ,@PostAdrs     = P.POST_ADRS
            ,@EmalAdrs     = P.EMAL_ADRS
            ,@InsrNumb     = P.INSR_NUMB
            ,@InsrDate     = P.INSR_DATE
            ,@EducDeg      = P.EDUC_DEG
            ,@CochFileNo   = P.COCH_FILE_NO
            ,@CbmtCode     = P.CBMT_CODE
            ,@DayType      = P.DAY_TYPE
            ,@AttnTime     = P.ATTN_TIME
            ,@CochCrtfDate = P.COCH_CRTF_DATE
            ,@CalcExpnType = P.CALC_EXPN_TYPE
            ,@ActvTag      = ISNULL(P.ACTV_TAG, '101')
            ,@BlodGrop     = P.BLOD_GROP
            ,@FngrPrnt     = P.FNGR_PRNT
            ,@SuntBuntDeptOrgnCode = P.Sunt_Bunt_Dept_Orgn_Code
            ,@SuntBuntDeptCode = P.Sunt_Bunt_Dept_Code
            ,@SuntBuntCode = P.Sunt_Bunt_Code
            ,@SuntCode = P.Sunt_Code
            ,@CordX = P.Cord_X
            ,@CordY = P.Cord_Y
            ,@MostDebtClng = P.MOST_DEBT_CLNG
            ,@ServNo = P.Serv_No
            ,@BrthPlac = P.BRTH_PLAC
            ,@IssuPLac = P.ISSU_PLAC
            ,@FathWork = P.FATH_WORK
            ,@HistDesc = P.HIST_DESC
            ,@IntrFileNo = P.INTR_FILE_NO
            ,@CntrCode = P.CNTR_CODE
        FROM Fighter_Public P
       WHERE P.FIGH_FILE_NO = @FileNo
         AND P.RQRO_RQST_RQID = @Rqid
         AND P.RQRO_RWNO = 1
         AND P.RECT_CODE = '001';
      
            
      IF NOT EXISTS(
         SELECT * 
         FROM Fighter_Public
         WHERE FIGH_FILE_NO = @FileNo
           AND RQRO_RQST_RQID = @Rqid
           AND RQRO_RWNO = 1
           AND RECT_CODE = '004'
      )
      BEGIN
         EXEC INS_FGPB_P
            @Prvn_Code = @PrvnCode
           ,@Regn_Code = @RegnCode
           ,@File_No   = @FileNo
           ,@Dise_Code = @DiseCode
           ,@Mtod_Code = @MtodCode
           ,@Ctgy_Code = @CtgyCode
           ,@Club_Code = @ClubCode
           ,@Rqro_Rqst_Rqid = @Rqid
           ,@Rqro_Rwno = 1
           ,@Rect_Code = '004' -- ذخیره نهایی
           ,@Frst_Name = @FrstName
           ,@Last_Name = @LastName
           ,@Fath_Name = @FathName
           ,@Sex_Type = @SexType
           ,@Natl_Code = @NatlCode
           ,@Brth_Date = @BrthDate
           ,@Cell_Phon = @CellPhon
           ,@Tell_Phon = @TellPhon
           ,@Coch_Deg  = @CochDeg
           ,@Gudg_Deg = @GudgDeg
           ,@Glob_Code = @GlobCode
           ,@Type      = @Type
           ,@Post_Adrs = @PostAdrs
           ,@Emal_Adrs = @EmalAdrs
           ,@Insr_Numb = @InsrNumb
           ,@Insr_Date = @InsrDate
           ,@Educ_Deg   = @EducDeg
           ,@Coch_File_No = @CochFileNo
           ,@Cbmt_Code = @CbmtCode
           ,@Day_Type = @DayType
           ,@Attn_Time = @AttnTime
           ,@Coch_Crtf_Date = @CochCrtfDate
           ,@Calc_Expn_Type = @CalcExpnType
           ,@Actv_Tag = @ActvTag
           ,@Blod_Grop = @BlodGrop
           ,@Fngr_Prnt = @FngrPrnt
           ,@Sunt_Bunt_Dept_Orgn_Code = @SuntBuntDeptOrgnCode
           ,@Sunt_Bunt_Dept_Code = @SuntBuntDeptCode
           ,@Sunt_Bunt_Code = @SuntBuntCode
           ,@Sunt_Code = @SuntCode
           ,@Cord_X = @CordX
           ,@Cord_Y = @CordY
           ,@Most_Debt_Clng = @MostDebtClng
           ,@Serv_No = @ServNo
           ,@Brth_Plac = @BrthPlac
           ,@Issu_Plac = @IssuPlac
           ,@Fath_Work = @FathWork
           ,@Hist_Desc = @HistDesc
           ,@Intr_File_No = @IntrFileNo
           ,@Cntr_Code = @CntrCode
           ,@Dpst_Acnt_Slry_Bank = NULL
           ,@Dpst_Acnt_Slry = NULL;

      END
      
      UPDATE Fighter
         SET CONF_STAT = '002'
       WHERE RQST_RQID = @Rqid;
      
      UPDATE Request
         SET RQST_STAT = '002'
       WHERE RQID = @Rqid;
      
      -- مشخص مربی 
      UPDATE Payment_Detail
         SET FIGH_FILE_NO = @CochFileNo
            ,CBMT_CODE_DNRM = @CbmtCode
       WHERE PYMT_RQST_RQID = @Rqid;         
         
      declare @StrtDate DateTime
             ,@EndDate  DATETIME
             ,@NumbMontOfer INT
             ,@NumbOfAttnMont INT
             ,@NumbOfAttnWeek INT
             ,@AttnDayType VARCHAR(3);
      
      SELECT @StrtDate = STRT_DATE, @EndDate = END_DATE
            ,@NumbMontOfer = NUMB_MONT_OFER
            ,@NumbOfAttnMont = NUMB_OF_ATTN_MONT
            ,@NumbOfAttnWeek = NUMB_OF_ATTN_WEEK
            ,@AttnDayType = ATTN_DAY_TYPE
        FROM Member_Ship
       WHERE RQRO_RQST_RQID = @Rqid
         AND FIGH_FILE_NO = @FileNo
         AND RECT_CODE = '001';
      

      SET @X = '<Process><Request rqstrqid="" rqtpcode="009" rqttcode="004" regncode="" prvncode=""><Request_Row fileno=""><Member_Ship strtdate="" enddate="" prntcont="1" numbmontofer="" numbofattnmont="" numbofattnweek="" attndaytype=""/></Request_Row></Request></Process>';
      SET @X.modify('replace value of (/Process/Request/@rqstrqid)[1] with sql:variable("@Rqid")');
      SET @X.modify('replace value of (/Process/Request/@regncode)[1] with sql:variable("@RegnCode")');
      SET @X.modify('replace value of (/Process/Request/@prvncode)[1] with sql:variable("@PrvnCode")');
      SET @X.modify('replace value of (/Process/Request/Request_Row/@fileno)[1] with sql:variable("@FileNo")');
      SET @X.modify('replace value of (/Process/Request/Request_Row/Member_Ship/@strtdate)[1] with sql:variable("@StrtDate")');
      SET @X.modify('replace value of (/Process/Request/Request_Row/Member_Ship/@enddate)[1] with sql:variable("@EndDate")');      
      SET @X.modify('replace value of (/Process/Request/Request_Row/Member_Ship/@numbmontofer)[1] with sql:variable("@NumbMontOfer")');
      SET @X.modify('replace value of (/Process/Request/Request_Row/Member_Ship/@numbofattnmont)[1] with sql:variable("@NumbOfAttnMont")');
      SET @X.modify('replace value of (/Process/Request/Request_Row/Member_Ship/@numbofattnweek)[1] with sql:variable("@NumbOfAttnWeek")');
      SET @X.modify('replace value of (/Process/Request/Request_Row/Member_Ship/@attndaytype)[1] with sql:variable("@AttnDayType")');
      EXEC UCC_RQST_P @X;
      
      SELECT @Rqid = R.RQID
        FROM Request R
       WHERE R.RQST_RQID = @Rqid
         AND R.RQST_STAT = '001'
         AND R.RQTP_CODE = '009'
         AND R.RQTT_CODE = '004';

      SET @X = '<Process><Request rqid="" rqtpcode="009" rqttcode="004" regncode="" prvncode=""><Request_Row rwno="1" fileno=""><Member_Ship strtdate="" enddate="" prntcont="1" numbmontofer="" numbofattnmont="" numbofattnweek="" attndaytype=""/></Request_Row></Request></Process>';
      SET @X.modify('replace value of (/Process/Request/@rqid)[1] with sql:variable("@Rqid")');
      SET @X.modify('replace value of (/Process/Request/@regncode)[1] with sql:variable("@RegnCode")');
      SET @X.modify('replace value of (/Process/Request/@prvncode)[1] with sql:variable("@PrvnCode")');
      SET @X.modify('replace value of (/Process/Request/Request_Row/@fileno)[1] with sql:variable("@FileNo")');
      SET @X.modify('replace value of (/Process/Request/Request_Row/Member_Ship/@strtdate)[1] with sql:variable("@StrtDate")');
      SET @X.modify('replace value of (/Process/Request/Request_Row/Member_Ship/@enddate)[1] with sql:variable("@EndDate")');
      SET @X.modify('replace value of (/Process/Request/Request_Row/Member_Ship/@numbmontofer)[1] with sql:variable("@NumbMontOfer")');
      SET @X.modify('replace value of (/Process/Request/Request_Row/Member_Ship/@numbofattnmont)[1] with sql:variable("@NumbOfAttnMont")');
      SET @X.modify('replace value of (/Process/Request/Request_Row/Member_Ship/@numbofattnweek)[1] with sql:variable("@NumbOfAttnWeek")');
      SET @X.modify('replace value of (/Process/Request/Request_Row/Member_Ship/@attndaytype)[1] with sql:variable("@AttnDayType")');
      EXEC UCC_SAVE_P @X;
      
      -- 1396/10/13 * ثبت گزینه ردیف عمومی
      UPDATE dbo.Member_Ship
         SET FGPB_RWNO_DNRM = 1
            ,FGPB_RECT_CODE_DNRM = '004'
       WHERE RQRO_RQST_RQID = @Rqid;
      
      IF EXISTS(
         SELECT *
           FROM dbo.Request R, dbo.Request_Row Rr, dbo.Payment P, dbo.Payment_Detail Pd, dbo.Expense E
          WHERE R.RQID = Rr.RQST_RQID
            AND R.RQID = P.RQST_RQID
            AND Rr.RQST_RQID = Pd.PYMT_RQST_RQID
            AND Rr.RWNO = Pd.RQRO_RWNO
            AND Pd.EXPN_CODE = E.CODE
            AND R.RQID = @OrgnRqid -- درخواست ثبت نام هنرجو
            AND E.PRVT_COCH_EXPN = '002' -- هزینه مربی خصوصی            
      )
      BEGIN
         -- ثبت درخواست جلسه خصوصی با مربی
         SET @X = '<Process><Request rqstrqid="" rqtpcode="021" rqttcode="004" regncode="" prvncode=""><Request_Row fileno=""><Member_Ship strtdate="" enddate="" prntcont="1" numbmontofer="" numbofattnmont="" numbofattnweek="" attndaytype=""/></Request_Row></Request></Process>';
         SET @X.modify('replace value of (/Process/Request/@rqstrqid)[1] with sql:variable("@Rqid")');
         SET @X.modify('replace value of (/Process/Request/@regncode)[1] with sql:variable("@RegnCode")');
         SET @X.modify('replace value of (/Process/Request/@prvncode)[1] with sql:variable("@PrvnCode")');
         SET @X.modify('replace value of (/Process/Request/Request_Row/@fileno)[1] with sql:variable("@FileNo")');
         SET @X.modify('replace value of (/Process/Request/Request_Row/Member_Ship/@strtdate)[1] with sql:variable("@StrtDate")');
         SET @X.modify('replace value of (/Process/Request/Request_Row/Member_Ship/@enddate)[1] with sql:variable("@EndDate")');      
         SET @X.modify('replace value of (/Process/Request/Request_Row/Member_Ship/@numbmontofer)[1] with sql:variable("@NumbMontOfer")');
         SET @X.modify('replace value of (/Process/Request/Request_Row/Member_Ship/@numbofattnmont)[1] with sql:variable("@NumbOfAttnMont")');
         SET @X.modify('replace value of (/Process/Request/Request_Row/Member_Ship/@numbofattnweek)[1] with sql:variable("@NumbOfAttnWeek")');
         SET @X.modify('replace value of (/Process/Request/Request_Row/Member_Ship/@attndaytype)[1] with sql:variable("@AttnDayType")');
         EXEC MBC_TRQT_P @X;
         
         SELECT @Rqid = R.RQID
           FROM Request R
          WHERE R.RQST_RQID = @Rqid
            AND R.RQST_STAT = '001'
            AND R.RQTP_CODE = '021'
            AND R.RQTT_CODE = '004';

         SET @X = '<Process><Request rqid=""></Request></Process>';
         SET @X.modify('replace value of (/Process/Request/@rqid)[1] with sql:variable("@Rqid")');
         EXEC MBC_TSAV_P @X;
      END
      
      -- 1396/10/05 * ثبت پیامک 
      IF @CellPhon IS NOT NULL AND LEN(@CellPhon) != 0 AND EXISTS(SELECT * FROM dbo.Request WHERE RQID = @OrgnRqid AND RQTT_CODE = '001')
      BEGIN
         DECLARE @MsgbStat VARCHAR(3)
                ,@MsgbText NVARCHAR(MAX)
                ,@ClubName NVARCHAR(250)
                ,@InsrCnamStat VARCHAR(3)
                ,@InsrFnamStat VARCHAR(3);
                
         SELECT @MsgbStat = STAT
               ,@MsgbText = MSGB_TEXT
               ,@ClubName = CLUB_NAME
               ,@InsrCnamStat = INSR_CNAM_STAT
               ,@InsrFnamStat = INSR_FNAM_STAT
           FROM dbo.Message_Broadcast
          WHERE MSGB_TYPE = '006';
         
         IF @MsgbStat = '002' 
         BEGIN
            IF @InsrFnamStat = '002'
               SET @MsgbText = (SELECT DOMN_DESC FROM dbo.[D$SXDC] WHERE VALU = @SexType) + N' ' + @FrstName + N' ' + @LastName + N' ' + @MsgbText;
            
            IF @InsrCnamStat = '002'
               SET @MsgbText = @MsgbText + N' ' + @ClubName;
               
            DECLARE @XMsg XML;
            SELECT @XMsg = (
               SELECT 5 AS '@subsys',
                      '002' AS '@linetype',
                      (
                        SELECT @CellPhon AS '@phonnumb',
                               (
                                   SELECT '006' AS '@type' 
                                          ,@MsgbText
                                      FOR XML PATH('Message'), TYPE 
                               ) 
                           FOR XML PATH('Contact'), TYPE
                      )
                 FOR XML PATH('Contacts'), ROOT('Process')                            
            );
            EXEC dbo.MSG_SEND_P @X = @XMsg -- xml
         END;
      END;      
      
      COMMIT TRAN T$ADM_TSAV_F;
   END TRY
   BEGIN CATCH
      SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN T$ADM_TSAV_F;
   END CATCH;
END
GO

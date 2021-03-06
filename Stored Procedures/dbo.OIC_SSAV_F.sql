SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[OIC_SSAV_F]
   @X XML
AS
BEGIN
   DECLARE @AP BIT
          ,@AccessString VARCHAR(250);

   SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>161</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 161 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   
	DECLARE @ErrorMessage NVARCHAR(MAX);

   BEGIN TRY
      BEGIN TRAN OCI_SSAVE_F_T;
      
      DECLARE @Rqid BIGINT;
	          
	   SELECT @Rqid = @X.query('//Request').value('(Request/@rqid)[1]'    , 'BIGINT');
      
      INSERT INTO Member_Ship (RQRO_RQST_RQID, RQRO_RWNO, FIGH_FILE_NO, RECT_CODE, [TYPE], STRT_DATE, END_DATE)
      SELECT RQRO_RQST_RQID, RQRO_RWNO, FIGH_FILE_NO, '004', [TYPE], STRT_DATE, END_DATE
        FROM Member_Ship
       WHERE RQRO_RQST_RQID = @Rqid
         AND RECT_CODE = '001';
      
      DECLARE @OldMbspRwno SMALLINT
             ,@NewMbspRwno SMALLINT
             ,@MbspFighFileNo BIGINT;
      
      SELECT @MbspFighFileNo = FIGH_FILE_NO
            ,@NewMbspRwno = RWNO
        FROM Member_Ship
       WHERE RQRO_RQST_RQID = @Rqid
         AND RECT_CODE = '004';         
     
      SELECT @OldMbspRwno = RWNO
        FROM Member_Ship
       WHERE RQRO_RQST_RQID = @Rqid
         AND RECT_CODE = '001';         
      
      INSERT INTO [Session] (MBSP_FIGH_FILE_NO, MBSP_RECT_CODE, MBSP_RWNO, SNID, SESN_TYPE, TIME_WATE, TOTL_SESN, SUM_MEET_MINT_DNRM)
      SELECT MBSP_FIGH_FILE_NO, '004', @NewMbspRwno, dbo.GNRT_NVID_U(), SESN_TYPE, TIME_WATE, TOTL_SESN, SUM_MEET_MINT_DNRM
        FROM [Session] 
       WHERE MBSP_FIGH_FILE_NO = @MbspFighFileNo
         AND MBSP_RECT_CODE = '001'
         AND MBSP_RWNO = @OldMbspRwno;
      
      DECLARE @Snid BIGINT;
      
      SELECT @Snid = SNID
        FROM [Session] 
       WHERE MBSP_FIGH_FILE_NO = @MbspFighFileNo
         AND MBSP_RECT_CODE = '004'
         AND MBSP_RWNO = @NewMbspRwno;
      
      DECLARE C$Snmt CURSOR FOR
         SELECT Expn_Code, Strt_Time, End_Time, Meet_Mint_Dnrm, Expn_Pric, Expn_Extr_Prct
           FROM Session_Meeting
          WHERE MBSP_FIGH_FILE_NO = @MbspFighFileNo
            AND MBSP_RECT_CODE = '001'
            AND MBSP_RWNO = @OldMbspRwno
            AND VALD_TYPE = '002';
      
      DECLARE @ExpnCode BIGINT
             ,@StrtTime TIME(0)
             ,@EndTime  TIME(0)
             ,@MeetMintDnrm INT
             ,@ExpnPric INT
             ,@ExpnExtrPrct INT;
      
      OPEN C$Snmt;
      L$FetchNextC$Snmt:
      FETCH NEXT FROM C$Snmt INTO @ExpnCode, @StrtTime, @EndTime, @MeetMintDnrm, @ExpnPric, @ExpnExtrPrct;
      
      IF @@FETCH_STATUS <> 0
         GOTO L$EndFetchC$Snmt;
      
      INSERT INTO Session_Meeting (MBSP_FIGH_FILE_NO, MBSP_RECT_CODE, MBSP_RWNO, SESN_SNID, RWNO, VALD_TYPE, STRT_TIME, END_TIME, MEET_MINT_DNRM, EXPN_CODE, EXPN_PRIC, EXPN_EXTR_PRCT)
      VALUES(@MbspFighFileNo, '004', @NewMbspRwno, @Snid, 0, '002', @StrtTime, @EndTime, @MeetMintDnrm, @ExpnCode, @ExpnPric, @ExpnExtrPrct);
         
      GOTO L$FetchNextC$Snmt;
      L$EndFetchC$Snmt:
      CLOSE C$Snmt;
      DEALLOCATE C$Snmt;
      	         
      UPDATE Payment_Detail
         SET PAY_STAT = '002'
            ,RCPT_MTOD = @x.query('//Payment_Detail[@code=sql:column("Code")]').value('(Payment_Detail/@rcptmtod)[1]', 'VARCHAR(3)')
       WHERE PYMT_RQST_RQID = @Rqid
         AND PAY_STAT = '001';
      
      UPDATE Request
         SET RQST_STAT = '002'
       WHERE RQID = @Rqid;
       
      COMMIT TRAN OCI_SSAV_F_T;
   END TRY
   BEGIN CATCH
      SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN T1;
   END CATCH

END;
GO

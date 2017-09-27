SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[OIC_OSAV_F]
   @X XML
AS 
BEGIN
   DECLARE @AP BIT
          ,@AccessString VARCHAR(250);

   SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>165</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 165 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   
	DECLARE @ErrorMessage NVARCHAR(MAX);

   BEGIN TRY
      BEGIN TRAN T1;
      
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
      
      INSERT INTO [Session] (MBSP_FIGH_FILE_NO, MBSP_RECT_CODE, MBSP_RWNO, SNID, SESN_TYPE, TOTL_SESN, CARD_NUMB, EXPN_CODE)
      SELECT MBSP_FIGH_FILE_NO, '004', @NewMbspRwno, dbo.GNRT_NVID_U(), SESN_TYPE, TOTL_SESN, CARD_NUMB, EXPN_CODE
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
      
      UPDATE Payment_Detail
         SET PAY_STAT = '002'
            ,RCPT_MTOD = @x.query('//Payment_Detail[@code=sql:column("Code")]').value('(Payment_Detail/@rcptmtod)[1]', 'VARCHAR(3)')
       WHERE PYMT_RQST_RQID = @Rqid
         AND PAY_STAT = '001';
      
      UPDATE Request
         SET RQST_STAT = '002'
       WHERE RQID = @Rqid;
       
      COMMIT TRAN T1;
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

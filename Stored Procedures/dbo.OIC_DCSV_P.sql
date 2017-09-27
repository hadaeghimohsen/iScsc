SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[OIC_DCSV_P]
	@X XML
AS
BEGIN
	DECLARE @AP BIT
       ,@AccessString VARCHAR(250);

   SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>189</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 189 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   
	DECLARE @ErrorMessage NVARCHAR(MAX);

   BEGIN TRY
      BEGIN TRAN T1;
      
      DECLARE @Rqid BIGINT
             ,@RemnTotlSesn SMALLINT;             
	          
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
      
      DECLARE C$Sessions CURSOR FOR
         SELECT S.EXPN_CODE, S.TOTL_SESN, S.CARD_NUMB, CBMT_CODE, SESN_SNID
           FROM Member_Ship m, dbo.Session s
          WHERE m.RQRO_RQST_RQID = @Rqid
            AND m.FIGH_FILE_NO = S.MBSP_FIGH_FILE_NO
            AND m.RECT_CODE = S.MBSP_RECT_CODE
            AND m.RWNO = S.MBSP_RWNO
            AND m.RECT_CODE = '001';
      
      DECLARE	
	      @ExpnCode [bigint] ,
	      @TotlSesn [smallint] ,
	      @CardNumb [varchar](50) ,
	      @CbmtCode [bigint],
	      @SesnSnid  BIGINT;
	   
      OPEN C$Sessions;
      Start_C$Sessions:
      FETCH NEXT FROM C$Sessions INTO @ExpnCode, @TotlSesn, @CardNumb, @CbmtCode, @SesnSnid;
      
      IF @@FETCH_STATUS <> 0
         GOTO End_C$Sessions;

      SELECT @RemnTotlSesn = S.TOTL_SESN - ISNULL(S.SUM_MEET_HELD_DNRM, 0)
        FROM Fighter F, Member_Ship M, [Session] S
       WHERE F.FILE_NO = M.FIGH_FILE_NO
         AND M.FIGH_FILE_NO = S.MBSP_FIGH_FILE_NO
         AND M.RECT_CODE = S.MBSP_RECT_CODE
         AND M.RWNO = S.MBSP_RWNO
         AND M.RECT_CODE = '004'
         AND M.RWNO = @NewMbspRwno - 1
         AND S.SNID = @SesnSnid;
         
      INSERT INTO [Session] (MBSP_FIGH_FILE_NO, MBSP_RECT_CODE, MBSP_RWNO, SNID, SESN_TYPE, TOTL_SESN, CARD_NUMB, EXPN_CODE, CBMT_CODE)
      SELECT MBSP_FIGH_FILE_NO, '004', @NewMbspRwno, dbo.GNRT_NVID_U(), SESN_TYPE, - TOTL_SESN + @RemnTotlSesn, CARD_NUMB, EXPN_CODE, CBMT_CODE
        FROM [Session] 
       WHERE MBSP_FIGH_FILE_NO = @MbspFighFileNo
         AND MBSP_RECT_CODE = '001'
         AND MBSP_RWNO = @OldMbspRwno
         AND ISNULL(SESN_SNID, 0) = ISNULL(@SesnSnid, 0);
      
      End_C$Sessions:
      CLOSE C$Sessions;
      DEALLOCATE C$Sessions;
      
      UPDATE Request
         SET RQST_STAT = '002'
       WHERE RQID = @Rqid;
       
      UPDATE Request_Letter
         SET REC_STAT = '002'
       WHERE RQST_RQID = @Rqid;
       
      UPDATE Finance_Document
         SET REC_STAT = '002'
       WHERE RQRO_RQST_RQID = @Rqid;
       
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
END
GO

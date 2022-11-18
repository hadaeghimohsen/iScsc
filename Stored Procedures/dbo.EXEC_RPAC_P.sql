SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[EXEC_RPAC_P]
	-- Add the parameters for the stored procedure here
	@X XML
AS
BEGIN
	BEGIN TRY	
	BEGIN TRAN T$Exec_Rpac_P	
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
   
   DECLARE @RpacType VARCHAR(3),
           @FromDate DATE,
           @ToDate DATE,
           @CochFileNo BIGINT,
           @CbmtCode BIGINT,
           @RecdOwnr VARCHAR(250),
           @RpapCode BIGINT,
           @SuntCode VARCHAR(4),
           @SuntBuntCode VARCHAR(2),
           @SuntBuntDeptCode VARCHAR(2),
           @SuntBuntDeptOrgnCode VARCHAR(2);
   
   SELECT @RpacType = @X.query('.').value('(Parameter/@rpactype)[1]', 'VARCHAR(3)')
         ,@FromDate = @X.query('.').value('(Parameter/@fromdate)[1]', 'DATE')
         ,@ToDate   = @X.query('.').value('(Parameter/@todate)[1]', 'DATE')
         ,@CochFileNo = @X.query('.').value('(Parameter/@cochfileno)[1]', 'BIGINT')
         ,@CbmtCode = @X.query('.').value('(Parameter/@cbmtcode)[1]', 'BIGINT')
         ,@RecdOwnr = @X.query('.').value('(Parameter/@recdownr)[1]', 'VARCHAR(250)')
         ,@SuntCode = @X.query('.').value('(Parameter/@suntcode)[1]', 'VARCHAR(4)')
         ,@SuntBuntCode = @X.query('.').value('(Parameter/@suntbuntcode)[1]', 'VARCHAR(2)')
         ,@SuntBuntDeptCode = @X.query('.').value('(Parameter/@suntbuntdeptcode)[1]', 'VARCHAR(2)')
         ,@SuntBuntDeptOrgnCode = @X.query('.').value('(Parameter/@suntbuntdeptorgncode)[1]', 'VARCHAR(2)');
   
   MERGE dbo.Report_Action_Parameter T
   USING (SELECT UPPER(SUSER_NAME()) AS CRET_BY, @RpacType AS RPAC_TYPE) S
   ON (T.CRET_BY = S.CRET_BY AND 
       T.RPAC_TYPE = s.RPAC_TYPE)
   WHEN NOT MATCHED THEN 
      INSERT (Code, RPAC_TYPE, FROM_DATE, TO_DATE)
      VALUES (0, s.RPAC_TYPE, @FromDate, @ToDate);
   
   SELECT @RpapCode = CODE
     FROM dbo.Report_Action_Parameter
    WHERE CRET_BY = UPPER(SUSER_NAME())
      AND RPAC_TYPE = @RpacType;
   
   UPDATE dbo.Report_Action_Parameter
      SET FROM_DATE = @FromDate
         ,TO_DATE = @ToDate
         ,COCH_FILE_NO = @CochFileNo
         ,CBMT_CODE = @CbmtCode
         ,RECD_OWNR = @RecdOwnr
         ,SUNT_CODE = @SuntCode
         ,SUNT_BUNT_CODE = @SuntBuntCode
         ,SUNT_BUNT_DEPT_CODE = @SuntBuntDeptCode
         ,SUNT_BUNT_DEPT_ORGN_CODE = @SuntBuntDeptOrgnCode
    WHERE CRET_BY = UPPER(SUSER_NAME())
      AND RPAC_TYPE = @RpacType;
      
   DELETE dbo.Report_Temporary WHERE RPAP_CODE = @RpapCode;
   
   -- گزارش کلاسی سرپرستان
   IF @RpacType = '001'
   BEGIN            
      /*
      INSERT INTO dbo.Report_Temporary
      ( CODE ,RPAP_CODE ,RQST_RQID ,COCH_FILE_NO ,CBMT_CODE ,FIGH_FILE_NO ,
      CTGY_CODE ,FNGR_PRNT_DNRM ,MBSP_RWNO ,MBSP_STRT_DATE ,MBSP_END_DATE ,MBSP_NUMB_ATTN ,
      MBSP_DEBT_DNRM ,MBSP_PYMT_AMNT, MBSP_SUM_EXPN_AMNT, MBSP_PYDS_AMNT, RQST_CRET_BY)
      SELECT dbo.GNRT_NVID_U() AS Code, 
             @RpapCode, 
             r.RQID,
             c.FILE_NO,
             fp.CBMT_CODE,
             f.FILE_NO,
             cb.CODE,
             fp.FNGR_PRNT,
             ms.RWNO,
             dbo.GET_MTOS_U(ms.STRT_DATE) AS STRT_DATE,
             dbo.GET_MTOS_U(ms.END_DATE) AS END_DATE,
             ms.SUM_ATTN_MONT_DNRM,
             (p.SUM_EXPN_PRIC - (p.SUM_RCPT_EXPN_PRIC + p.SUM_PYMT_DSCN_DNRM)) AS DEBT_DNRM,
             p.SUM_RCPT_EXPN_PRIC,
             p.SUM_EXPN_PRIC,
             p.SUM_PYMT_DSCN_DNRM,
             r.CRET_BY
       FROM  dbo.Payment_Detail pd ,
             dbo.Fighter c ,
             dbo.Category_Belt cb ,
             dbo.Method m ,
             dbo.Payment p ,
             dbo.Request r ,
             dbo.Request_Row rr,
             dbo.Fighter f,
             dbo.Member_Ship ms,
             dbo.Fighter_Public fp
       WHERE pd.PYMT_CASH_CODE = p.CASH_CODE
         AND pd.PYMT_RQST_RQID = p.RQST_RQID
         AND p.RQST_RQID = r.RQID
         AND c.FILE_NO = pd.FIGH_FILE_NO
         AND pd.CTGY_CODE_DNRM = cb.CODE
         AND pd.MTOD_CODE_DNRM = m.CODE
         AND m.CODE = cb.MTOD_CODE
         AND pd.PYMT_RQST_RQID = r.RQID
         AND pd.RQRO_RWNO = rr.RWNO
         AND r.RQID = rr.RQST_RQID
         AND rr.FIGH_FILE_NO = f.FILE_NO
         AND ms.FIGH_FILE_NO = fp.FIGH_FILE_NO
         AND ISNULL(ms.FGPB_RECT_CODE_DNRM, '004') = fp.RECT_CODE
         AND ISNULL(ms.FGPB_RWNO_DNRM, 1) = fp.RWNO
         AND p.PYMT_STAT != '002'
         AND 
         (
            (r.RQTP_CODE = '009' AND rr.RQST_RQID = ms.RQRO_RQST_RQID AND rr.RWNO = ms.RQRO_RWNO AND ms.RECT_CODE = '004') OR 
            (r.RQTP_CODE = '001' AND /*rr.RQST_RQID = ms.RQRO_RQST_RQID AND rr.RWNO = ms.RQRO_RWNO AND*/ ms.FIGH_FILE_NO = rr.FIGH_FILE_NO AND ms.RWNO = 1 AND ms.RECT_CODE = '004' )--ms.RQRO_RQST_RQID = (SELECT rt.RQID FROM dbo.Request rt WHERE r.RQID = rt.RQST_RQID AND rt.RQTP_CODE = '009' AND rt.RQTT_CODE = '004'))               
         )
         
         AND r.RQST_STAT = '002'
         AND r.RQTP_CODE IN ( '001', '009' )
         
         AND f.CONF_STAT = '002'
         AND f.ACTV_TAG_DNRM >= '101'
         
         AND (@CbmtCode IS NULL OR @CbmtCode = 0 OR (pd.CBMT_CODE_DNRM = @CbmtCode))            
         AND (@CochFileNo IS NULL OR @CochFileNo = 0 OR (pd.FIGH_FILE_NO = @CochFileNo))
         
         AND (@FromDate IS NULL OR (CAST(ms.STRT_DATE AS DATE) >= @FromDate))
         AND (@ToDate IS NULL OR (CAST(ms.STRT_DATE AS DATE) <= @ToDate))
         
         AND (@RecdOwnr IS NULL OR @RecdOwnr = '' OR (R.CRET_BY IN (SELECT u.Item FROM dbo.SplitString(@RecdOwnr, ':') u)));
      */   
      INSERT INTO dbo.Report_Temporary
      ( CODE ,RPAP_CODE ,RQST_RQID ,COCH_FILE_NO ,CBMT_CODE ,FIGH_FILE_NO ,
      CTGY_CODE ,FNGR_PRNT_DNRM ,MBSP_RWNO ,MBSP_STRT_DATE ,MBSP_END_DATE ,
      MBSP_NUMB_ATTN ,MBSP_DEBT_DNRM ,MBSP_PYMT_AMNT ,MBSP_SUM_EXPN_AMNT ,
      MBSP_PYDS_AMNT ,RQST_CRET_BY, FGPB_RWNO)
      select dbo.GNRT_NVID_U(), @RpapCode, r.rqid, NULL, NULL, r.FIGH_FILE_NO,
             NULL, NULL, ms.RWNO, dbo.GET_MTOS_U(ms.STRT_DATE), dbo.GET_MTOS_U(ms.END_DATE),
             ms.SUM_ATTN_MONT_DNRM, NULL, NULL, NULL, 
             NULL, r.CRET_BY, ms.FGPB_RWNO_DNRM      
        FROM V#Request r, V#Member_Ship ms
       where r.RQTP_CODE in ('001', '009')
         and (
			      (r.RQTP_CODE = '009' AND r.RQID = ms.RQRO_RQST_RQID ) OR 
			      (r.RQTP_CODE = '001' AND ms.FIGH_FILE_NO = r.FIGH_FILE_NO AND ms.RWNO = 1 AND ms.RECT_CODE = '004' )--ms.RQRO_RQST_RQID = (SELECT rt.RQID FROM dbo.Request rt WHERE r.RQID = rt.RQST_RQID AND rt.RQTP_CODE = '009' AND rt.RQTT_CODE = '004'))               
	          )
         and CAST(ms.STRT_DATE AS DATE) between @FromDate and @ToDate;
      
      UPDATE rt
         SET rt.COCH_FILE_NO = fp.COCH_FILE_NO,
             rt.CTGY_CODE = fp.CTGY_CODE,
             rt.CBMT_CODE = fp.CBMT_CODE,
             rt.FNGR_PRNT_DNRM = fp.FNGR_PRNT,
             rt.MBSP_DEBT_DNRM = (p.SUM_EXPN_PRIC - (p.SUM_RCPT_EXPN_PRIC + p.SUM_PYMT_DSCN_DNRM)),
             rt.MBSP_PYMT_AMNT = p.SUM_RCPT_EXPN_PRIC,
             rt.MBSP_SUM_EXPN_AMNT = p.SUM_EXPN_PRIC,
             rt.MBSP_PYDS_AMNT = p.SUM_PYMT_DSCN_DNRM
        FROM dbo.Report_Temporary rt, dbo.V#Fighter_Public fp, dbo.Payment p
       WHERE rt.RPAP_CODE = @RpapCode
         AND rt.FIGH_FILE_NO = fp.FIGH_FILE_NO
         AND rt.FGPB_RWNO = fp.RWNO
         AND rt.RQST_RQID = p.RQST_RQID
         AND (@CbmtCode IS NULL OR @CbmtCode = 0 OR (fp.CBMT_CODE = @CbmtCode))            
         AND (@CochFileNo IS NULL OR @CochFileNo = 0 OR (fp.COCH_FILE_NO = @CochFileNo))
         AND (@RecdOwnr IS NULL OR @RecdOwnr = '' OR (rt.RQST_CRET_BY IN (SELECT u.Item FROM dbo.SplitString(@RecdOwnr, ':') u)));
      
      DELETE dbo.Report_Temporary
       WHERE RPAP_CODE = @RpapCode
         AND COCH_FILE_NO IS NULL;
   END
   -- گزارش عملکرد افراد سازمانی
   ELSE IF @RpacType = '002' 
   BEGIN
      INSERT INTO dbo.Report_Temporary ( CODE ,RPAP_CODE ,FIGH_FILE_NO )
      SELECT dbo.GNRT_NVID_U(), @RpapCode, f.FILE_NO
        FROM dbo.V#Fighter f, dbo.Report_Action_Parameter a
       WHERE a.CODE = @RpapCode
         AND f.SUNT_BUNT_DEPT_ORGN_CODE_DNRM + f.SUNT_BUNT_DEPT_CODE_DNRM + f.SUNT_BUNT_CODE_DNRM + f.SUNT_CODE_DNRM = 
             a.SUNT_BUNT_DEPT_ORGN_CODE + a.SUNT_BUNT_DEPT_CODE + a.SUNT_BUNT_CODE + a.SUNT_CODE;
   END 
   
   -- Insert statements for procedure here
   COMMIT TRAN [T$Exec_Rpac_P]
	END TRY
	BEGIN CATCH 
	   DECLARE @ErrorMessage NVARCHAR(MAX) = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN [T$Exec_Rpac_P];
	END CATCH
END
GO

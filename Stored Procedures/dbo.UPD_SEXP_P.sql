SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[UPD_SEXP_P]   
   @X XML
AS 
   /*
      <Request rqid="">
         <Payment cashcode="">
            <Payment_Detail code=""/>
         </Payment>
      </Request>
   */
BEGIN
   BEGIN TRY
   BEGIN TRAN UPD_SEXP_P_T
      DECLARE @Rqid BIGINT
             ,@PymtCashCode BIGINT
             ,@PymtPydtCode BIGINT
             ,@ExpnPric BIGINT
             ,@PydtDesc NVARCHAR(250)
             ,@Qnty REAL
             ,@FighFileNo BIGINT
             ,@CbmtCodeDnrm BIGINT
             ,@MtodCodeDnrm BIGINT
             ,@CtgyCodeDnrm BIGINT
             ,@ExpnCode BIGINT
             ,@TranStat VARCHAR(3)
             ,@TranBy VARCHAR(250)
             ,@TranDate DATE
             ,@TranCbmtCode BIGINT
             ,@TranMtodCode BIGINT
             ,@TranCtgyCode BIGINT
             ,@TranExpnCode BIGINT
             ,@ExprDate DATE
             ,@MbspFighFileNo BIGINT
             ,@MbspRwno SMALLINT
             ,@MbspRectCode VARCHAR(3) = '004'
             ,@FromNumb BIGINT
             ,@ToNumb BIGINT;
             
      SELECT @Rqid = @X.query('Request').value('(Request/@rqid)[1]', 'BIGINT')
            ,@PymtCashCode = @X.query('Request/Payment').value('(Payment/@cashcode)[1]', 'BIGINT')
            ,@PymtPydtCode = @X.query('Request/Payment/Payment_Detail').value('(Payment_Detail/@code)[1]', 'BIGINT')
            ,@ExpnCode = @X.query('Request/Payment/Payment_Detail').value('(Payment_Detail/@expncode)[1]', 'BIGINT')
            ,@ExpnPric = @X.query('Request/Payment/Payment_Detail').value('(Payment_Detail/@expnpric)[1]', 'BIGINT')
            ,@PydtDesc = @X.query('Request/Payment/Payment_Detail').value('(Payment_Detail/@pydtdesc)[1]', 'NVARCHAR(250)')
            ,@Qnty = @X.query('Request/Payment/Payment_Detail').value('(Payment_Detail/@qnty)[1]', 'REAL')
            --,@FighFileNo = @X.query('Request/Payment/Payment_Detail').value('(Payment_Detail/@fighfileno)[1]', 'BIGINT')
            ,@CbmtCodeDnrm = @X.query('Request/Payment/Payment_Detail').value('(Payment_Detail/@cbmtcodednrm)[1]', 'BIGINT')
            ,@MtodCodeDnrm = @X.query('Request/Payment/Payment_Detail').value('(Payment_Detail/@mtodcodednrm)[1]', 'BIGINT')
            ,@CtgyCodeDnrm = @X.query('Request/Payment/Payment_Detail').value('(Payment_Detail/@ctgycodednrm)[1]', 'BIGINT')
            ,@TranStat = @X.query('Request/Payment/Payment_Detail').value('(Payment_Detail/@transtat)[1]', 'VARCHAR(3)')
            ,@TranBy = @X.query('Request/Payment/Payment_Detail').value('(Payment_Detail/@tranby)[1]', 'VARCHAR(250)')
            ,@TranDate = @X.query('Request/Payment/Payment_Detail').value('(Payment_Detail/@trandate)[1]', 'DATE')
            ,@TranCbmtCode = @X.query('Request/Payment/Payment_Detail').value('(Payment_Detail/@trancbmtcode)[1]', 'BIGINT')
            ,@TranMtodCode = @X.query('Request/Payment/Payment_Detail').value('(Payment_Detail/@tranmtodcode)[1]', 'BIGINT')
            ,@TranCtgyCode = @X.query('Request/Payment/Payment_Detail').value('(Payment_Detail/@tranctgycode)[1]', 'BIGINT')
            ,@TranExpnCode = @X.query('Request/Payment/Payment_Detail').value('(Payment_Detail/@tranexpncode)[1]', 'BIGINT')
            ,@ExprDate = @X.query('Request/Payment/Payment_Detail').value('(Payment_Detail/@exprdate)[1]', 'DATE')
            ,@MbspFighFileNo = @X.query('Request/Payment/Payment_Detail').value('(Payment_Detail/@mbspfighfileno)[1]', 'BIGINT')
            ,@MbspRwno = @X.query('Request/Payment/Payment_Detail').value('(Payment_Detail/@mbsprwno)[1]', 'SMALLINT')
            ,@MbspRectCode = @X.query('Request/Payment/Payment_Detail').value('(Payment_Detail/@mbsprectcode)[1]', 'VARCHAR(3)')
            ,@FromNumb = @X.query('Request/Payment/Payment_Detail').value('(Payment_Detail/@fromnumb)[1]', 'BIGINT')
            ,@ToNumb = @X.query('Request/Payment/Payment_Detail').value('(Payment_Detail/@tonumb)[1]', 'BIGINT');
      
      IF @MbspRwno = 0 OR @MbspRwno IS NULL
         SELECT @MbspFighFileNo = NULL, 
                @MbspRectCode = NULL,
                @MbspRwno = NULL;
      ELSE
         SELECT @MbspFighFileNo = rr.FIGH_FILE_NO,
                @MbspRectCode = '004'
           FROM dbo.Request_Row rr
          WHERE rr.RQST_RQID = @Rqid;
      
      IF @ExprDate = '1900-01-01'
         SET @ExprDate = NULL;
      
      -- 1401/02/04
      IF @FromNumb = 0 SET @FromNumb = NULL;
      IF @ToNumb = 0 SET @ToNumb = NULL;
      
      IF @CbmtCodeDnrm = 0 OR @CbmtCodeDnrm IS NULL
      BEGIN
         SET @CbmtCodeDnrm = NULL;
         SET @FighFileNo = NULL;
      END
      ELSE
         SELECT @FighFileNo = COCH_FILE_NO
               ,@MtodCodeDnrm = MTOD_CODE
           FROM dbo.Club_Method
          WHERE code = @CbmtCodeDnrm;
      
      IF @TranStat IS NULL OR @TranStat = '003'
      BEGIN
         SELECT @TranBy = NULL
               ,@TranDate = NULL
               ,@TranCbmtCode = NULL
               ,@TranMtodCode = NULL
               ,@TranCtgyCode = NULL
               ,@TranExpnCode = NULL;                      
      END
      ELSE IF @TranStat IN ( '001', '002' )
      BEGIN
         SELECT @TranMtodCode = MTOD_CODE
           FROM dbo.Category_Belt
          WHERE CODE = @TranCtgyCode;
      END
      
      -- 1397/02/31
      SELECT @MtodCodeDnrm = MTOD_CODE
            ,@CtgyCodeDnrm = CTGY_CODE
        FROM dbo.Expense
       WHERE CODE = @ExpnCode;
      
      IF @TranStat = '002'
      BEGIN
         DECLARE @TmpFighFileNo BIGINT
                ,@TmpCbmtCode BIGINT
                ,@TmpMtodCode BIGINT
                ,@TmpCtgyCode BIGINT
                ,@TmpExpnCode BIGINT;
         
         -- ثبت ایتم های فعلی
         SELECT @TmpFighFileNo = @FighFileNo
               ,@TmpCbmtCode   = @CbmtCodeDnrm
               ,@TmpMtodCode   = @MtodCodeDnrm
               ,@TmpCtgyCode   = @CtgyCodeDnrm
               ,@TmpExpnCode   = @ExpnCode;         
         
         SELECT @FighFileNo = (SELECT COCH_FILE_NO FROM dbo.Club_Method WHERE CODE = @TranCbmtCode)
               ,@CbmtCodeDnrm = @TranCbmtCode
               ,@MtodCodeDnrm = @TranMtodCode
               ,@CtgyCodeDnrm = @TranCtgyCode
               ,@ExpnCode = @TranExpnCode;
         
         SELECT @TranCbmtCode   = @TmpCbmtCode
               ,@TranMtodCode   = @TmpMtodCode
               ,@TranCtgyCode   = @TmpCtgyCode
               ,@TranExpnCode   = @TmpExpnCode;
      END
      
      -- 1400/01/01 * لاگ برداری از عملیات کاربر
      IF EXISTS (SELECT * FROM dbo.Request r WHERE r.RQID = @Rqid AND r.RQST_STAT = '002')
      BEGIN      
   	   DECLARE @XTemp XML = (
   	      SELECT rr.FIGH_FILE_NO AS '@fileno',
   	             '008' AS '@type',
   	             N'از صورتحساب به مبلغ ' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, p.SUM_EXPN_PRIC), 1), '.00', '') + N' بابت ' + rt.RQTP_DESC + 
   	             CASE WHEN p.SUM_PYMT_DSCN_DNRM != 0 THEN N' با تخفیف ' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, p.SUM_PYMT_DSCN_DNRM), 1), '.00', '') ELSE N'' END +
   	             CASE WHEN p.SUM_RCPT_EXPN_PRIC != 0 THEN N' با مبلغ پرداختی ' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, p.SUM_RCPT_EXPN_PRIC), 1), '.00', '') ELSE N'' END +
   	             N' که توسط کاربر ' + p.CRET_BY + N' ایجاد شده بود توسط کاربر ' + UPPER(SUSER_NAME()) + N' یک قلم از اقلام صورتحساب که ' + e.EXPN_DESC + N' به تعداد ' + CAST(pd.QNTY AS VARCHAR(10)) + 
   	             N' به ارزش ' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, pd.QNTY * pd.EXPN_PRIC), 1), '.00', '') + N' از صورتحساب مشتری ویرایش شد' AS '@text'
   	        FROM dbo.Payment p, dbo.Request r, dbo.Request_Row rr, dbo.Request_Type rt, dbo.Payment_Detail pd, dbo.Expense e
   	       WHERE p.RQST_RQID = r.RQID
   	         AND r.RQID = rr.RQST_RQID
   	         AND r.RQTP_CODE = rt.CODE
   	         AND pd.PYMT_RQST_RQID = p.RQST_RQID
   	         AND pd.EXPN_CODE = e.CODE
   	         AND r.RQID = @Rqid
   	         AND pd.CODE = @PymtPydtCode
   	         FOR XML PATH('Log')
   	   );
   	   EXEC dbo.INS_LGOP_P @X = @XTemp; -- xml
      END
      
      UPDATE Payment_Detail
         SET EXPN_PRIC = @ExpnPric
            ,PYDT_DESC = @PydtDesc
            ,QNTY = @Qnty  
            ,FIGH_FILE_NO   = @FighFileNo
            ,CBMT_CODE_DNRM = @CbmtCodeDnrm
            ,MTOD_CODE_DNRM = @MtodCodeDnrm
            ,CTGY_CODE_DNRM = @CtgyCodeDnrm
            ,EXPN_CODE      = @ExpnCode
            ,TRAN_STAT      = @TranStat
            ,TRAN_BY        = @TranBy
            ,TRAN_DATE      = @TranDate
            ,TRAN_CBMT_CODE = @TranCbmtCode
            ,TRAN_MTOD_CODE = @TranMtodCode
            ,TRAN_CTGY_CODE = @TranCtgyCode
            ,TRAN_EXPN_CODE = @TranExpnCode
            ,EXPR_DATE = @ExprDate
            ,MBSP_FIGH_FILE_NO = @MbspFighFileNo
            ,MBSP_RWNO = @MbspRwno
            ,MBSP_RECT_CODE = @MbspRectCode
            ,FROM_NUMB = @FromNumb
            ,TO_NUMB = @ToNumb
       WHERE PYMT_RQST_RQID = @Rqid
         AND PYMT_CASH_CODE = @PymtCashCode
         AND CODE = @PymtPydtCode;
         
      COMMIT TRAN UPD_SEXP_P_T;
   END TRY
   BEGIN CATCH
      DECLARE @ErrorMessage NVARCHAR(MAX);
      SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN UPD_SEXP_P_T;
   END CATCH
END
GO

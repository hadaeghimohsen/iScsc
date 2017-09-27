SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[PYDS_CHCK_U]
(
	-- Add the parameters for the function here
	@X XML
)
RETURNS XML
AS
   /* 
   <Request rqid="">
      <Request_Row rwno="">
         <Expense code="" qnty=""/>
      </Request_Row>
   </Request>
   */
BEGIN
	-- Declare the return variable here
	DECLARE @Rslt XML;
	DECLARE @Rqid BIGINT
	       ,@RqtpCode VARCHAR(3)
	       ,@RqttCode VARCHAR(3)
	       ,@RqroRwno SMALLINT
	       ,@ExpnCode BIGINT
	       ,@Qnty     SMALLINT;
   
   SELECT @Rqid     = @X.query('//Request').value('(Request/@rqid)[1]', 'BIGINT')
         ,@RqroRwno = @X.query('//Request_Row').value('(Request_Row/@rwno)[1]', 'SMALLINT')
         ,@ExpnCode = @X.query('//Expense').value('(Expense/@code)[1]', 'BIGINT')
         ,@Qnty     = @X.query('//Expense').value('(Expense/@qnty)[1]', 'SMALLINT');
         
   SELECT @RqtpCode = RQTP_CODE
         ,@RqttCode = RQTT_CODE
     FROM Request 
    WHERE RQID = @Rqid;
   
   DECLARE @SuntBuntDeptOrgnCode VARCHAR(2)
          ,@SuntBuntDeptCode     VARCHAR(2)
          ,@SuntBuntCode         VARCHAR(2)
          ,@SuntCode             VARCHAR(4)
          ,@ReglYear             SMALLINT
          ,@ReglCode             INT
          ,@EpitCode             BIGINT
          ,@CovrDsct             VARCHAR(3);
   
   IF @RqtpCode IN ('001')
   BEGIN   
      SELECT @SuntBuntDeptOrgnCode = SUNT_BUNT_DEPT_ORGN_CODE
            ,@SuntBuntDeptCode = SUNT_BUNT_DEPT_CODE
            ,@SuntBuntCode = SUNT_BUNT_CODE
            ,@SuntCode = SUNT_CODE
        FROM Fighter_Public
       WHERE RQRO_RQST_RQID = @Rqid
         AND RQRO_RWNO = @RqroRwno
         AND RECT_CODE = '001';      
   END
   ELSE 
   BEGIN
      SELECT @SuntBuntDeptOrgnCode = SUNT_BUNT_DEPT_ORGN_CODE_DNRM
            ,@SuntBuntDeptCode = SUNT_BUNT_DEPT_CODE_DNRM
            ,@SuntBuntCode = SUNT_BUNT_CODE_DNRM
            ,@SuntCode = SUNT_CODE_DNRM
        FROM Fighter
       WHERE RQST_RQID = @Rqid;
   END
   
   SELECT @ReglYear = YEAR
         ,@ReglCode = CODE
     FROM Regulation
    WHERE [TYPE] = '001'
      AND REGL_STAT = '002';
   
   SELECT @EpitCode = Et.EPIT_CODE
         ,@CovrDsct = COVR_DSCT
     FROM Expense E, Expense_Type Et
    WHERE E.CODE = @ExpnCode
      AND E.EXTP_CODE = Et.CODE;      
   
   -- محاسبه تخفیف عادی
   IF EXISTS(
      SELECT *
        FROM Basic_Calculate_Discount
       WHERE SUNT_BUNT_DEPT_ORGN_CODE = @SuntBuntDeptOrgnCode
         AND SUNT_BUNT_DEPT_CODE = @SuntBuntDeptCode
         AND SUNT_BUNT_CODE = @SuntBuntCode
         AND SUNT_CODE = @SuntCode
         AND REGL_YEAR = @ReglYear
         AND REGL_CODE = @ReglCode
         AND EPIT_CODE = @EpitCode
         AND ACTN_TYPE = '001' -- تخفیف عادی
         AND STAT = '002'
   )
   BEGIN
      DECLARE @AmntDsct INT
             ,@PrctDsct INT
             ,@DsctType VARCHAR(3)
             ,@Pric     INT
             ,@DsctDesc NVARCHAR(500);
             
      SELECT @AmntDsct = AMNT_DSCT
            ,@PrctDsct = PRCT_DSCT
            ,@DsctType = DSCT_TYPE
            ,@DsctDesc = DSCT_DESC 
        FROM Basic_Calculate_Discount
       WHERE SUNT_BUNT_DEPT_ORGN_CODE = @SuntBuntDeptOrgnCode
         AND SUNT_BUNT_DEPT_CODE = @SuntBuntDeptCode
         AND SUNT_BUNT_CODE = @SuntBuntCode
         AND SUNT_CODE = @SuntCode
         AND REGL_YEAR = @ReglYear
         AND REGL_CODE = @ReglCode
         AND EPIT_CODE = @EpitCode
         AND ACTN_TYPE = '001'
         AND STAT = '002';

      SELECT @Pric = PRIC + ISNULL(EXTR_PRCT, 0)
        FROM Expense
       WHERE CODE = @ExpnCode;

      -- %
      IF @DsctType = '001'   
      BEGIN         
         SET @Pric = ROUND((@Pric * @Qnty) * @PrctDsct / 100 , -3) ;
      END
      -- $
      ELSE IF @DsctType = '002'
      BEGIN
         IF @Pric * @Qnty > @AmntDsct
            --SET @Pric = ROUND(@Pric * @Qnty - @AmntDsct , -3);
            SET @Pric = ROUND(@AmntDsct, -3);
      END
      SET @Rslt = 
         (
            SELECT 1 AS '@type'
                  ,@Pric AS '@amntdsct'
                  ,@DsctDesc AS '@dsctdesc'
            FOR XML PATH('Result')
         );
      RETURN @Rslt;
   END
   
   -- محاسبه تخفیف دوره ای و بازه ای
   IF EXISTS(
      SELECT *
        FROM Basic_Calculate_Discount
       WHERE SUNT_BUNT_DEPT_ORGN_CODE = @SuntBuntDeptOrgnCode
         AND SUNT_BUNT_DEPT_CODE = @SuntBuntDeptCode
         AND SUNT_BUNT_CODE = @SuntBuntCode
         AND SUNT_CODE = @SuntCode
         AND REGL_YEAR = @ReglYear
         AND REGL_CODE = @ReglCode
         AND EPIT_CODE = @EpitCode
         AND ACTN_TYPE != '001' -- تخفیف دوره و تخفیف بازه زمانی
         AND STAT = '002'
         AND (
            -- دوره ای
            (ACTN_TYPE = '002' AND DATEPART(M, GETDATE())*100 + DATEPART(D, GETDATE()) BETWEEN DATEPART(M, FROM_DATE)*100 + DATEPART(D, FROM_DATE) AND DATEPART(M, TO_DATE)*100 +   DATEPART(D, TO_DATE)) OR
            -- بازه زمانی
            (ACTN_TYPE = '003' AND CAST(GETDATE() AS DATE) BETWEEN FROM_DATE AND TO_DATE)
         )
   )
   BEGIN
      SELECT @AmntDsct = AMNT_DSCT
            ,@PrctDsct = PRCT_DSCT
            ,@DsctType = DSCT_TYPE
            ,@DsctDesc = DSCT_DESC
        FROM Basic_Calculate_Discount
       WHERE SUNT_BUNT_DEPT_ORGN_CODE = @SuntBuntDeptOrgnCode
         AND SUNT_BUNT_DEPT_CODE = @SuntBuntDeptCode
         AND SUNT_BUNT_CODE = @SuntBuntCode
         AND SUNT_CODE = @SuntCode
         AND REGL_YEAR = @ReglYear
         AND REGL_CODE = @ReglCode
         AND EPIT_CODE = @EpitCode
         AND ACTN_TYPE != '001'
         AND STAT = '002'
         AND (
            -- دوره ای
            (ACTN_TYPE = '002' AND DATEPART(M, GETDATE())*100 + DATEPART(D, GETDATE()) BETWEEN DATEPART(M, FROM_DATE)*100 + DATEPART(D, FROM_DATE) AND DATEPART(M, TO_DATE)*100 +   DATEPART(D, TO_DATE)) OR
            -- بازه زمانی
            (ACTN_TYPE = '003' AND CAST(GETDATE() AS DATE) BETWEEN FROM_DATE AND TO_DATE)
         );

      SELECT @Pric = PRIC + ISNULL(EXTR_PRCT, 0)
        FROM Expense
       WHERE CODE = @ExpnCode;

      -- %
      IF @DsctType = '001'   
      BEGIN         
         SET @Pric = ROUND((@Pric * @Qnty) * @PrctDsct / 100 , -3) ;
      END
      -- $
      ELSE IF @DsctType = '002'
      BEGIN
         IF @Pric * @Qnty > @AmntDsct
            --SET @Pric = ROUND(@Pric * @Qnty - @AmntDsct , -3);
            SET @Pric = ROUND(@AmntDsct, -3);
      END
      SET @Rslt = 
         (
            SELECT 1 AS '@type'
                  ,@Pric AS '@amntdsct'
                  ,@DsctDesc AS '@dsctdesc'
            FOR XML PATH('Result')
         );
      RETURN @Rslt;
   END

	-- Return the result of the function
	RETURN '<Result type="0"/>';

END
GO

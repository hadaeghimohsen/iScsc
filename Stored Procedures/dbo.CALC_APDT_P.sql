SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[CALC_APDT_P]
	-- Add the parameters for the stored procedure here
    @Agop_Code BIGINT ,
    @Rwno BIGINT
AS
BEGIN
    UPDATE  T
    SET     T.END_TIME = ISNULL(END_TIME, GETDATE())
    FROM    dbo.Aggregation_Operation_Detail T ,
            dbo.Expense E
    WHERE   T.AGOP_CODE = @Agop_Code
            AND T.RWNO = @Rwno
            AND T.EXPN_CODE = E.CODE
            AND T.EXPN_CODE IS NOT NULL;    
      
    UPDATE  T
    SET     T.EXPN_PRIC = ROUND(E.PRIC * T.TOTL_MINT_DNRM / 60, -3) ,
            T.EXPN_EXTR_PRCT = ROUND(E.EXTR_PRCT * T.TOTL_MINT_DNRM / 60, -3) ,
            T.TOTL_AMNT_DNRM = ISNULL(T.TOTL_BUFE_AMNT_DNRM, 0)
            + ISNULL(T.EXPN_PRIC, 0) + ISNULL(T.EXPN_EXTR_PRCT, 0)
    FROM    dbo.Aggregation_Operation_Detail T ,
            dbo.Expense E
    WHERE   T.AGOP_CODE = @Agop_Code
            AND T.RWNO = @Rwno
            AND T.EXPN_CODE = E.CODE
            AND T.EXPN_CODE IS NOT NULL;    
   
   -- 1398/08/25 * اگر مشتری قدیمی باشد و مهمان آزاد نباشد
   -- و مبلغ سپرده در حساب مشتری وجود دارد
    IF EXISTS ( SELECT  *
                FROM    dbo.Aggregation_Operation_Detail a ,
                        dbo.Fighter f
                WHERE   a.FIGH_FILE_NO = f.FILE_NO
                        AND a.AGOP_CODE = @Agop_Code
                        AND a.RWNO = @Rwno
                        AND f.FGPB_TYPE_DNRM = '001'
                        AND f.DPST_AMNT_DNRM > 0 )
    BEGIN 
   -- 1398/08/25 * بررسی اینکه محاسبه تخفیف سپرده گذاری باید انجام شود یا خیر
        DECLARE @ExpnCode BIGINT ,
            @Pric BIGINT ,
            @Qnty INT;
        
        DECLARE @XTmp XML = (
            SELECT '016' AS '@rqtpcode' 
                  ,'007' AS '@rqttcode'
                  ,1 AS 'Request_Row/@rwno',
                  a.EXPN_CODE AS 'Request_Row/Expense/@code',
                  a.NUMB AS 'Request_Row/Expense/@qnty',
                  a.EXPN_PRIC AS 'Request_Row/Expense/@pric',
                  a.AGOP_CODE AS 'Request_Row/Aggregation_Operation_Detail/@agopcode',
                  a.RWNO AS 'Request_Row/Aggregation_Operation_Detail/@rwno'
              FROM dbo.Aggregation_Operation_Detail a
             WHERE a.AGOP_CODE = @Agop_Code
               AND a.RWNO = @Rwno
               FOR XML PATH('Request')
        );
        
        SELECT @XTmp = dbo.PYDS_CHCK_U(@XTmp);
        
        -- محاسبه تخفیف مقداری داشته یا خیر
        IF @XTmp.query('Result').value('(Result/@type)[1]', 'SMALLINT') = 1
        BEGIN
           DECLARE @BcdsCode BIGINT;
           SELECT @Pric = @XTmp.query('Result').value('(Result/@amntdsct)[1]', 'BIGINT')
                 ,@BcdsCode = @XTmp.query('Result').value('(Result/@bcdscode)[1]', 'BIGINT')
           UPDATE a
              SET a.PYDS_AMNT = @Pric
                 ,a.DPST_AMNT = CASE 
                                   WHEN f.DPST_AMNT_DNRM >= ( (ISNULL(a.NUMB, 1) * ( ISNULL(a.EXPN_PRIC, 0) + ISNULL(a.EXPN_EXTR_PRCT, 0))) + a.TOTL_BUFE_AMNT_DNRM - @Pric ) THEN
                                        (ISNULL(a.NUMB, 1) * ( ISNULL(a.EXPN_PRIC, 0) + ISNULL(a.EXPN_EXTR_PRCT, 0))) + a.TOTL_BUFE_AMNT_DNRM - @Pric
                                   ELSE f.DPST_AMNT_DNRM
                                END 
                 ,a.BCDS_CODE = @BcdsCode
                 ,a.AODT_DESC = @XTmp.query('Result').value('(Result/@dsctdesc)[1]', 'NVARCHAR(250)')
             FROM dbo.Aggregation_Operation_Detail a, dbo.Fighter f
            WHERE a.AGOP_CODE = @Agop_Code
              AND a.RWNO = @Rwno
              AND a.FIGH_FILE_NO = f.FILE_NO;             
        END
    END;         
END;
GO

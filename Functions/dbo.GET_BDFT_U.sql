SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[GET_BDFT_U]
(
	@X XML
)
RETURNS VARCHAR(3)
AS
BEGIN
	DECLARE @FileNo BIGINT
	       ,@RectCode VARCHAR(3)
	       ,@Rwno int
	       ,@MesrType VARCHAR(3)
	       ,@Valu VARCHAR(3)
	       ,@SexType VARCHAR(3)
	       ,@Age SMALLINT;
	
	SELECT @FileNo = @X.query('//Body_Fitness').value('(Body_Fitness/@fighfileno)[1]', 'BIGINT')
	      ,@RectCode = @X.query('//Body_Fitness').value('(Body_Fitness/@rectcode)[1]', 'VARCHAR(3)')
	      ,@Rwno = @X.query('//Body_Fitness').value('(Body_Fitness/@rwno)[1]', 'INT');
	
	SELECT @MesrType = MESR_TYPE
	      ,@Age = AGE_DNRM
	      ,@SexType = SEX_TYPE_DNRM
	  FROM Body_Fitness
	 WHERE FIGH_FILE_NO = @FileNo
	   AND RECT_CODE = @RectCode
	   AND RWNO = @Rwno;
	
	DECLARE @V1 REAL
	       ,@V2 REAL
	       ,@V3 VARCHAR(3)
	       ,@Calc REAL;
	       
	
	IF @MesrType = '001'
	BEGIN
	   SELECT @V1 = CASE BODY_TYPE WHEN '001' THEN MESR_VALU END
	         ,@V2 = CASE BODY_TYPE WHEN '002' THEN MESR_VALU END
	     FROM Body_Fitness_Measurement
	    WHERE BDFT_FIGH_FILE_NO = @FileNo
	      AND BDFT_RECT_CODE = @RectCode
	      AND BDFT_RWNO = @Rwno
	      AND BODY_TYPE IN ('001', '002');
	   
	   SET @Calc = @V1 / @V2;
	   
	   SELECT @Valu = 
	      CASE @SexType
	         WHEN '001' THEN
	            CASE 
	               WHEN @Calc >= 0.6 AND @Calc < 0.8 THEN '001'
	               WHEN @Calc >= 0.8 AND @Calc < 0.9 THEN '002'
	               WHEN @Calc >= 0.9 AND @Calc < 1.0 THEN '003'
	               WHEN @Calc >= 1.0                 THEN '004'
	            END
	         WHEN '002' THEN	         
	            CASE 
	               WHEN @Calc >= 0.6 AND @Calc < 0.7 THEN '001'
	               WHEN @Calc >= 0.7 AND @Calc < 0.8 THEN '002'
	               WHEN @Calc >= 0.8 AND @Calc < 0.9 THEN '003'
	               WHEN @Calc >= 0.9                 THEN '004'
	            END
	       END
	END
	ELSE IF @MesrType = '002'
	BEGIN
	   SELECT @V1 = CASE BODY_TYPE WHEN '001' THEN MESR_VALU END
	         ,@V2 = CASE BODY_TYPE WHEN '003' THEN MESR_VALU END
	     FROM Body_Fitness_Measurement
	    WHERE BDFT_FIGH_FILE_NO = @FileNo
	      AND BDFT_RECT_CODE = @RectCode
	      AND BDFT_RWNO = @Rwno
	      AND BODY_TYPE IN ('001', '003');
	   
	   SET @Calc = @V1 / @V2;
	   
	   SELECT @Valu = 
	      CASE 
            WHEN @Calc > 0.5 THEN '005'
            ELSE                  '006'
         END
	END
	ELSE IF @MesrType = '003'
	BEGIN
	   SELECT @V1 = C.BMI_DNRM
	         ,@V2 = B.AGE_DNRM
	         ,@V3 = B.SEX_TYPE_DNRM
	     FROM Body_Fitness B, Calculate_Calorie C
	    WHERE B.CLCL_FIGH_FILE_NO = C.FIGH_FILE_NO
	      AND B.CLCL_RECT_CODE = C.RECT_CODE
	      AND B.CLCL_RWNO = C.RWNO;
	   
	   SET @Calc = (1.2 * @V1) + (0.23 * @V2) - 5.4 * (10.8 * (CASE @V3 WHEN '001' THEN 0 ELSE 1 END));
	   
	   SELECT @Valu = 
	      CASE WHEN @V3 = '001' AND @Calc > 25  THEN '008'
	           WHEN @V3 = '001' AND @Calc <= 25 THEN '007'
	           WHEN @V3 = '002' AND @Calc > 33  THEN '008'
	           WHEN @V3 = '002' AND @Calc <= 33 THEN '007'
	      END
	END
	
	RETURN @Valu;
	
END
GO

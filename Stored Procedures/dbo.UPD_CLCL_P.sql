SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[UPD_CLCL_P]
	@Rqid BIGINT
  ,@RqroRwno SMALLINT
  ,@FileNo BIGINT
  ,@RectCode VARCHAR(3)
  ,@Hegh REAL
  ,@Wegh SMALLINT
  ,@TranTime INT
AS
BEGIN
   UPDATE Calculate_Calorie
      SET HEGH = @Hegh
         ,WEGH = @Wegh
         ,TRAN_TIME = @TranTime
    WHERE RQRO_RQST_RQID = @Rqid
      AND RQRO_RWNO = @RqroRwno
      AND FIGH_FILE_NO = @FileNo
      AND RECT_CODE = @RectCode;
END
GO

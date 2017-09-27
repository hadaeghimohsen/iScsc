SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[INS_HERT_P]
	@Rqid BIGINT
  ,@RqroRwno SMALLINT
  ,@FileNo BIGINT
  ,@RectCode VARCHAR(3)
  ,@RestHertRate REAL  
AS
BEGIN
   INSERT INTO Heart_Zone(RQRO_RQST_RQID, RQRO_RWNO, FIGH_FILE_NO, RECT_CODE, REST_HERT_RATE)
   VALUES (@Rqid, @RqroRwno, @FileNo, @RectCode, @RestHertRate);
END
GO

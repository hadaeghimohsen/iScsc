SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[V#Fighter_Public] AS
SELECT * FROM Fighter_Public WHERE RECT_CODE = '004';
GO

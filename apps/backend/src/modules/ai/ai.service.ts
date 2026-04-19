import { Injectable, BadRequestException, InternalServerErrorException } from '@nestjs/common';
import { GoogleGenerativeAI } from '@google/generative-ai';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class AiService {
  private genAI: GoogleGenerativeAI;

  constructor(private prisma: PrismaService) {
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      console.warn('GEMINI_API_KEY chưa được cấu hình trong .env');
      this.genAI = new GoogleGenerativeAI('DUMMY_KEY');
    } else {
      this.genAI = new GoogleGenerativeAI(apiKey);
    }
  }

  async analyzeIssue(imageBuffer: Buffer, mimeType: string) {
    try {
      // 1. Fetch available services to give AI context
      const services = await this.prisma.service.findMany({
        select: {
          id: true,
          name: true,
          basePrice: true,
        },
      });

      // 2. Prepare Generative AI
      const model = this.genAI.getGenerativeModel({
        model: 'gemini-2.5-flash',
      });

      // 3. Prepare Prompt
      const prompt = `Bạn là một chuyên gia chẩn đoán sửa chữa, dọn dẹp tại nhà. Hãy phân tích hình ảnh được cung cấp và xác định hư hỏng.
Sau đó, hãy chọn 1 dịch vụ phù hợp nhất từ danh sách dịch vụ sau (dưới dạng JSON):
${JSON.stringify(services)}

Hãy ước lượng chi phí sửa chữa tối thiểu và tối đa (VNĐ) và đưa ra chẩn đoán ngắn gọn.
Trả về KẾT QUẢ DUY NHẤT LÀ MỘT OBJECT JSON THEO ĐÚNG CẤU TRÚC DƯỚI ĐÂY (không được có thẻ markdown \`\`\`json hay text dư thừa nào khác):
{
  "issueTitle": "Tên lỗi ngắn gọn",
  "recommendedServiceId": ID_DICH_VU_TRONG_DANH_SACH,
  "recommendedServiceName": "Tên dịch vụ tương ứng",
  "minPrice": 150000,
  "maxPrice": 300000,
  "confidenceScore": 95,
  "aiNotes": "Mô tả chi tiết nguyên nhân và cách khắc phục để người dùng/thợ biết trước"
}`;

      // 4. Call Gemini
      const imagePart = {
        inlineData: {
          data: imageBuffer.toString('base64'),
          mimeType: mimeType,
        },
      };

      let responseText = '';
      let retries = 3;
      while (retries > 0) {
        try {
          const result = await model.generateContent([prompt, imagePart]);
          responseText = result.response.text();
          break; // success, exit retry loop
        } catch (genError) {
          retries--;
          console.warn(`[AI Retry] Gemini failed, retries left: ${retries}. Error: ${genError.message}`);
          if (retries === 0) throw genError;
          // Wait 2 seconds before retrying
          await new Promise((resolve) => setTimeout(resolve, 2000));
        }
      }

      // 5. Clean and Parse JSON
      let cleanJson = responseText.trim();
      if (cleanJson.startsWith('```json')) {
        cleanJson = cleanJson
          .replace(/^```json/, '')
          .replace(/```$/, '')
          .trim();
      } else if (cleanJson.startsWith('```')) {
        cleanJson = cleanJson
          .replace(/^```/, '')
          .replace(/```$/, '')
          .trim();
      }

      console.log('[AI] Processed result:', cleanJson);
      const parsedData = JSON.parse(cleanJson);
      
      // Fallback mechanism if AI hallucinates an ID that doesn't exist
      const isIdValid = services.some(s => s.id === parsedData.recommendedServiceId);
      if (!isIdValid && services.length > 0) {
        parsedData.recommendedServiceId = services[0].id;
        parsedData.recommendedServiceName = services[0].name;
      }

      return parsedData;
    } catch (error) {
      console.error('[AI Service Error]:', error);
      throw new InternalServerErrorException(
        'Hệ thống AI xử lý ảnh đang quá tải (Google Servers). Xin vui lòng thử lại sau vài giây! Chi tiết: ' + error.message,
      );
    }
  }
}

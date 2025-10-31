#!/usr/bin/env python3
"""
스크린샷을 애플 개발자 커넥트 요구사항에 맞게 리사이즈
- 1242 × 2688px (iPhone 11 Pro Max, XS Max)
- 1284 × 2778px (iPhone 12/13/14 Pro Max)
"""

from PIL import Image
import os
import glob

def resize_screenshot(input_path, target_width=1284, target_height=2778):
    """스크린샷을 지정된 크기로 리사이즈"""
    try:
        img = Image.open(input_path)
        original_size = img.size
        print(f"\n파일: {os.path.basename(input_path)}")
        print(f"  원본 크기: {original_size[0]} × {original_size[1]}px")
        
        # 세로 모드인지 확인
        if original_size[0] > original_size[1]:
            # 가로 모드면 세로로 회전
            img = img.rotate(90, expand=True)
            print(f"  회전 적용됨")
        
        # 비율을 유지하면서 리사이즈
        # 먼저 타겟 높이에 맞춤
        ratio = target_height / img.size[1]
        new_width = int(img.size[0] * ratio)
        new_height = target_height
        
        img_resized = img.resize((new_width, new_height), Image.Resampling.LANCZOS)
        
        # 너비가 타겟보다 크면 중앙에서 크롭
        if new_width > target_width:
            left = (new_width - target_width) // 2
            img_resized = img_resized.crop((left, 0, left + target_width, new_height))
        # 너비가 타겟보다 작으면 양쪽에 검은색 추가
        elif new_width < target_width:
            new_img = Image.new('RGB', (target_width, target_height), (0, 0, 0))
            left = (target_width - new_width) // 2
            new_img.paste(img_resized, (left, 0))
            img_resized = new_img
        
        # 출력 파일명 생성
        output_path = input_path.replace('.PNG', '_resized.png')
        img_resized.save(output_path, 'PNG', quality=95)
        
        print(f"  최종 크기: {img_resized.size[0]} × {img_resized.size[1]}px")
        print(f"  저장됨: {os.path.basename(output_path)}")
        return True
        
    except Exception as e:
        print(f"  ❌ 오류: {e}")
        return False

def main():
    # IMG_로 시작하는 PNG 파일 찾기
    screenshots = sorted(glob.glob('IMG_*.PNG'))
    
    if not screenshots:
        print("❌ IMG_*.PNG 파일을 찾을 수 없습니다.")
        return
    
    print(f"찾은 스크린샷: {len(screenshots)}개")
    print("="*60)
    
    success_count = 0
    for screenshot in screenshots:
        if resize_screenshot(screenshot):
            success_count += 1
    
    print("\n" + "="*60)
    print(f"\n✅ {success_count}/{len(screenshots)}개의 스크린샷이 성공적으로 리사이즈되었습니다.")
    print(f"\n📱 최종 크기: 1284 × 2778px (iPhone 12/13/14 Pro Max)")
    print(f"📁 파일명: IMG_XXXX_resized.png")

if __name__ == '__main__':
    main()

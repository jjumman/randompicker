#!/usr/bin/env python3
"""
Random Picker 앱 아이콘 생성 스크립트
사용자가 제공한 app_icon.png를 기반으로 모든 크기의 아이콘을 생성합니다.
"""

from PIL import Image
import os

def resize_icon(source_image, size):
    """소스 이미지를 지정된 크기로 리사이즈"""
    # 고품질 리샘플링을 사용하여 리사이즈
    return source_image.resize((size, size), Image.Resampling.LANCZOS)

def main():
    """모든 필요한 아이콘 크기 생성"""
    icon_sizes = {
        'Icon-App-20x20@1x.png': 20,
        'Icon-App-20x20@2x.png': 40,
        'Icon-App-20x20@3x.png': 60,
        'Icon-App-29x29@1x.png': 29,
        'Icon-App-29x29@2x.png': 58,
        'Icon-App-29x29@3x.png': 87,
        'Icon-App-40x40@1x.png': 40,
        'Icon-App-40x40@2x.png': 80,
        'Icon-App-40x40@3x.png': 120,
        'Icon-App-60x60@2x.png': 120,
        'Icon-App-60x60@3x.png': 180,
        'Icon-App-76x76@1x.png': 76,
        'Icon-App-76x76@2x.png': 152,
        'Icon-App-83.5x83.5@2x.png': 167,
        'Icon-App-1024x1024@1x.png': 1024,
    }
    
    base_path = 'ios/Runner/Assets.xcassets/AppIcon.appiconset/'
    source_path = base_path + 'app_icon.png'
    
    # 소스 이미지 로드
    print(f"소스 이미지 로딩 중: {source_path}")
    try:
        source_image = Image.open(source_path)
        # RGBA 모드로 변환 (투명도 지원)
        if source_image.mode != 'RGBA':
            source_image = source_image.convert('RGBA')
        print(f"  원본 크기: {source_image.size}")
    except Exception as e:
        print(f"❌ 오류: 소스 이미지를 로드할 수 없습니다: {e}")
        return
    
    print("\n앱 아이콘 생성 중...")
    for filename, size in icon_sizes.items():
        print(f"  생성 중: {filename} ({size}x{size})")
        icon = resize_icon(source_image, size)
        # RGB 모드로 변환하여 저장 (iOS 아이콘은 투명도 불필요)
        icon_rgb = icon.convert('RGB')
        icon_rgb.save(base_path + filename, 'PNG')
    
    print(f"\n✅ 총 {len(icon_sizes)}개의 아이콘이 생성되었습니다!")
    print(f"📁 위치: {base_path}")

if __name__ == '__main__':
    main()

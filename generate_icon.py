#!/usr/bin/env python3
"""
Random Picker 앱 아이콘 생성 스크립트
다채로운 원들이 있는 앱 아이콘을 생성합니다.
"""

from PIL import Image, ImageDraw
import math

def create_app_icon(size):
    """지정된 크기의 앱 아이콘 생성"""
    # 그라데이션 배경 생성
    img = Image.new('RGB', (size, size), '#1a1a2e')
    draw = ImageDraw.Draw(img, 'RGBA')
    
    # 배경 그라데이션
    for i in range(size):
        ratio = i / size
        r = int(26 + (46 - 26) * ratio)
        g = int(26 + (46 - 26) * ratio)
        b = int(46 + (78 - 46) * ratio)
        draw.line([(0, i), (size, i)], fill=(r, g, b))
    
    # 다채로운 원들 그리기
    colors = [
        (255, 107, 107, 200),  # 빨강
        (78, 205, 196, 200),   # 청록
        (255, 205, 86, 200),   # 노랑
        (154, 125, 255, 200),  # 보라
        (255, 159, 243, 200),  # 분홍
    ]
    
    center_x, center_y = size // 2, size // 2
    
    # 5개의 원을 원형으로 배치
    num_circles = 5
    radius_offset = size * 0.28
    circle_size = size * 0.15
    
    for i in range(num_circles):
        angle = (2 * math.pi / num_circles) * i - math.pi / 2
        x = center_x + radius_offset * math.cos(angle)
        y = center_y + radius_offset * math.sin(angle)
        
        color = colors[i % len(colors)]
        
        # 외곽 발광 효과
        for j in range(3, 0, -1):
            glow_size = circle_size + j * 3
            glow_color = (*color[:3], int(color[3] * 0.3 * (4 - j) / 3))
            draw.ellipse(
                [x - glow_size, y - glow_size, x + glow_size, y + glow_size],
                fill=glow_color
            )
        
        # 메인 원
        draw.ellipse(
            [x - circle_size, y - circle_size, x + circle_size, y + circle_size],
            fill=color
        )
        
        # 하이라이트
        highlight_size = circle_size * 0.4
        highlight_x = x - circle_size * 0.3
        highlight_y = y - circle_size * 0.3
        draw.ellipse(
            [highlight_x - highlight_size, highlight_y - highlight_size,
             highlight_x + highlight_size, highlight_y + highlight_size],
            fill=(255, 255, 255, 100)
        )
    
    # 중앙에 작은 흰색 원 (터치 포인트를 상징)
    center_circle_size = size * 0.08
    draw.ellipse(
        [center_x - center_circle_size, center_y - center_circle_size,
         center_x + center_circle_size, center_y + center_circle_size],
        fill=(255, 255, 255, 230)
    )
    
    return img

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
    
    print("앱 아이콘 생성 중...")
    for filename, size in icon_sizes.items():
        print(f"  생성 중: {filename} ({size}x{size})")
        icon = create_app_icon(size)
        icon.save(base_path + filename)
    
    print(f"\n✅ 총 {len(icon_sizes)}개의 아이콘이 생성되었습니다!")
    print(f"📁 위치: {base_path}")

if __name__ == '__main__':
    main()

#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from PIL import Image, ImageDraw, ImageFont
import os

def create_realistic_home_screenshot(width, height):
    """홈 화면 스크린샷 생성 - Flutter Material Design 스타일"""
    img = Image.new('RGB', (width, height), '#FAFAFA')  # Material Design background
    draw = ImageDraw.Draw(img)
    
    # 폰트 사이즈 계산 (해상도에 따라 조정)
    scale = min(width, height) / 400
    title_size = int(24 * scale)
    subtitle_size = int(18 * scale)
    body_size = int(16 * scale)
    small_size = int(14 * scale)
    
    try:
        # 시스템 폰트 사용
        title_font = ImageFont.truetype("/System/Library/Fonts/SF-Pro-Display-Bold.otf", title_size)
        subtitle_font = ImageFont.truetype("/System/Library/Fonts/SF-Pro-Display-Medium.otf", subtitle_size)
        body_font = ImageFont.truetype("/System/Library/Fonts/SF-Pro-Text-Regular.otf", body_size)
        small_font = ImageFont.truetype("/System/Library/Fonts/SF-Pro-Text-Regular.otf", small_size)
    except:
        # 폴백 폰트
        try:
            title_font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", title_size)
            subtitle_font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", subtitle_size)
            body_font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", body_size)
            small_font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", small_size)
        except:
            title_font = ImageFont.load_default()
            subtitle_font = ImageFont.load_default()
            body_font = ImageFont.load_default()
            small_font = ImageFont.load_default()
    
    # 상태바 영역
    status_height = int(50 * scale)
    
    # AppBar 영역
    appbar_height = int(56 * scale)
    draw.rectangle([0, status_height, width, status_height + appbar_height], fill='#1976D2')  # Material Blue
    
    # AppBar 제목
    draw.text((int(20 * scale), status_height + int(16 * scale)), "비움", fill='white', font=title_font)
    
    # 햄버거 메뉴 아이콘 (간단한 라인들)
    menu_x = width - int(60 * scale)
    menu_y = status_height + int(20 * scale)
    for i in range(3):
        y = menu_y + i * int(6 * scale)
        draw.rectangle([menu_x, y, menu_x + int(20 * scale), y + int(2 * scale)], fill='white')
    
    # 본문 시작 위치
    content_start = status_height + appbar_height + int(20 * scale)
    
    # 동기부여 메시지 카드
    card_margin = int(16 * scale)
    card_height = int(80 * scale)
    card_y = content_start
    draw.rounded_rectangle([card_margin, card_y, width - card_margin, card_y + card_height], 
                          radius=int(8 * scale), fill='#E3F2FD', outline='#BBDEFB', width=2)
    draw.text((card_margin + int(16 * scale), card_y + int(20 * scale)), 
              "오늘도 잘 비워보자! 🌱", fill='#1565C0', font=subtitle_font)
    draw.text((card_margin + int(16 * scale), card_y + int(45 * scale)), 
              "작은 실천이 큰 변화를 만듭니다.", fill='#1976D2', font=body_font)
    
    # 오늘의 감정 섹션
    emotion_y = card_y + card_height + int(30 * scale)
    draw.text((card_margin, emotion_y), "오늘의 기분", fill='#333333', font=subtitle_font)
    
    # 감정 버튼들
    emotions = ['😊', '😢', '😡', '😴', '🤔']
    emotion_colors = ['#4CAF50', '#2196F3', '#F44336', '#9C27B0', '#FF9800']
    button_size = int(50 * scale)
    button_y = emotion_y + int(40 * scale)
    
    for i, (emotion, color) in enumerate(zip(emotions, emotion_colors)):
        x = card_margin + i * (button_size + int(15 * scale))
        # 선택된 것처럼 첫 번째 버튼 강조
        if i == 0:
            draw.ellipse([x-3, button_y-3, x + button_size+3, button_y + button_size+3], fill=color)
        draw.ellipse([x, button_y, x + button_size, button_y + button_size], 
                    fill='white', outline=color, width=3)
        # 이모지 대신 컬러 점으로 표시
        center_x, center_y = x + button_size//2, button_y + button_size//2
        draw.ellipse([center_x-8, center_y-8, center_x+8, center_y+8], fill=color)
    
    # 목표 리스트 섹션
    goals_y = button_y + button_size + int(40 * scale)
    draw.text((card_margin, goals_y), "오늘의 목표", fill='#333333', font=subtitle_font)
    
    # 목표 항목들
    goals = [
        {"icon": "🏃", "name": "운동하기", "status": "success", "color": "#4CAF50"},
        {"icon": "📚", "name": "독서 30분", "status": "pending", "color": "#9E9E9E"},
        {"icon": "💧", "name": "물 2L 마시기", "status": "fail", "color": "#F44336"}
    ]
    
    goal_item_height = int(70 * scale)
    
    for i, goal in enumerate(goals):
        item_y = goals_y + int(40 * scale) + i * (goal_item_height + int(10 * scale))
        
        # 목표 아이템 배경
        draw.rounded_rectangle([card_margin, item_y, width - card_margin, item_y + goal_item_height],
                              radius=int(8 * scale), fill='white', outline='#E0E0E0', width=1)
        
        # 아이콘 영역 (컬러 원으로 대체)
        icon_size = int(40 * scale)
        icon_x = card_margin + int(16 * scale)
        icon_y = item_y + int(15 * scale)
        draw.ellipse([icon_x, icon_y, icon_x + icon_size, icon_y + icon_size], fill=goal["color"])
        
        # 목표 이름
        text_x = icon_x + icon_size + int(16 * scale)
        draw.text((text_x, item_y + int(10 * scale)), goal["name"], fill='#333333', font=body_font)
        
        # 상태 표시
        if goal["status"] == "success":
            status_text = "✓ 완료"
            status_color = "#4CAF50"
        elif goal["status"] == "fail":
            status_text = "✗ 실패"
            status_color = "#F44336"
        else:
            status_text = "대기중"
            status_color = "#9E9E9E"
            
        draw.text((text_x, item_y + int(35 * scale)), status_text, fill=status_color, font=small_font)
        
        # 기록 버튼
        button_width = int(60 * scale)
        button_height = int(30 * scale)
        button_x = width - card_margin - button_width - int(16 * scale)
        button_y = item_y + int(20 * scale)
        
        draw.rounded_rectangle([button_x, button_y, button_x + button_width, button_y + button_height],
                              radius=int(4 * scale), fill='#1976D2', outline='#1976D2')
        draw.text((button_x + int(15 * scale), button_y + int(8 * scale)), "기록", fill='white', font=small_font)
    
    return img

def create_realistic_calendar_screenshot(width, height):
    """캘린더 화면 스크린샷 생성"""
    img = Image.new('RGB', (width, height), '#FAFAFA')
    draw = ImageDraw.Draw(img)
    
    scale = min(width, height) / 400
    title_size = int(24 * scale)
    subtitle_size = int(18 * scale)
    body_size = int(16 * scale)
    small_size = int(14 * scale)
    
    try:
        title_font = ImageFont.truetype("/System/Library/Fonts/SF-Pro-Display-Bold.otf", title_size)
        subtitle_font = ImageFont.truetype("/System/Library/Fonts/SF-Pro-Display-Medium.otf", subtitle_size)
        body_font = ImageFont.truetype("/System/Library/Fonts/SF-Pro-Text-Regular.otf", body_size)
        small_font = ImageFont.truetype("/System/Library/Fonts/SF-Pro-Text-Regular.otf", small_size)
    except:
        try:
            title_font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", title_size)
            subtitle_font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", subtitle_size)
            body_font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", body_size)
            small_font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", small_size)
        except:
            title_font = subtitle_font = body_font = small_font = ImageFont.load_default()
    
    status_height = int(50 * scale)
    appbar_height = int(56 * scale)
    
    # AppBar
    draw.rectangle([0, status_height, width, status_height + appbar_height], fill='#1976D2')
    draw.text((int(20 * scale), status_height + int(16 * scale)), "캘린더", fill='white', font=title_font)
    
    content_start = status_height + appbar_height + int(20 * scale)
    
    # 월/년 표시
    draw.text((int(20 * scale), content_start), "2024년 12월", fill='#333333', font=subtitle_font)
    
    # 주간/월간 토글 버튼
    toggle_y = content_start + int(40 * scale)
    toggle_width = int(80 * scale)
    toggle_height = int(35 * scale)
    
    # 주간 버튼 (선택됨)
    draw.rounded_rectangle([int(20 * scale), toggle_y, int(20 * scale) + toggle_width, toggle_y + toggle_height],
                          radius=int(4 * scale), fill='#1976D2')
    draw.text((int(35 * scale), toggle_y + int(8 * scale)), "주간", fill='white', font=body_font)
    
    # 월간 버튼
    draw.rounded_rectangle([int(20 * scale) + toggle_width + int(10 * scale), toggle_y, 
                           int(20 * scale) + toggle_width * 2 + int(10 * scale), toggle_y + toggle_height],
                          radius=int(4 * scale), fill='white', outline='#1976D2', width=2)
    draw.text((int(45 * scale) + toggle_width, toggle_y + int(8 * scale)), "월간", fill='#1976D2', font=body_font)
    
    # 캘린더 그리드
    calendar_start_y = toggle_y + toggle_height + int(30 * scale)
    
    # 요일 헤더
    weekdays = ['일', '월', '화', '수', '목', '금', '토']
    cell_width = (width - int(40 * scale)) // 7
    cell_height = int(50 * scale)
    
    for i, day in enumerate(weekdays):
        x = int(20 * scale) + i * cell_width
        draw.text((x + cell_width//2 - int(10 * scale), calendar_start_y), day, fill='#666666', font=body_font)
    
    # 캘린더 날짜들
    grid_start_y = calendar_start_y + int(40 * scale)
    
    # 샘플 날짜 데이터 (12월)
    dates = [
        [None, None, None, None, None, 1, 2],
        [3, 4, 5, 6, 7, 8, 9],
        [10, 11, 12, 13, 14, 15, 16],
        [17, 18, 19, 20, 21, 22, 23],
        [24, 25, 26, 27, 28, 29, 30],
        [31, None, None, None, None, None, None]
    ]
    
    # 성공/실패 상태 (샘플)
    success_days = [1, 3, 5, 8, 10, 12, 15, 18, 20, 22]
    fail_days = [2, 6, 9, 13, 16, 19, 23]
    
    for week_idx, week in enumerate(dates):
        for day_idx, date in enumerate(week):
            if date is None:
                continue
                
            x = int(20 * scale) + day_idx * cell_width
            y = grid_start_y + week_idx * cell_height
            
            # 날짜 배경 색상
            bg_color = 'white'
            text_color = '#333333'
            
            if date in success_days:
                bg_color = '#E8F5E8'  # 연한 초록
                text_color = '#2E7D32'
            elif date in fail_days:
                bg_color = '#FFEBEE'  # 연한 빨강
                text_color = '#C62828'
            
            # 오늘 날짜 강조 (15일)
            if date == 15:
                bg_color = '#1976D2'
                text_color = 'white'
            
            # 날짜 셀 그리기
            draw.rounded_rectangle([x + 2, y + 2, x + cell_width - 2, y + cell_height - 2],
                                  radius=int(4 * scale), fill=bg_color, outline='#E0E0E0')
            
            # 날짜 텍스트
            text_x = x + cell_width//2 - int(8 * scale)
            text_y = y + cell_height//2 - int(8 * scale)
            draw.text((text_x, text_y), str(date), fill=text_color, font=body_font)
            
            # 성공/실패 표시 점
            if date in success_days:
                dot_x = x + cell_width - int(8 * scale)
                dot_y = y + int(5 * scale)
                draw.ellipse([dot_x-3, dot_y-3, dot_x+3, dot_y+3], fill='#4CAF50')
            elif date in fail_days:
                dot_x = x + cell_width - int(8 * scale)
                dot_y = y + int(5 * scale)
                draw.ellipse([dot_x-3, dot_y-3, dot_x+3, dot_y+3], fill='#F44336')
    
    # 범례
    legend_y = grid_start_y + 6 * cell_height + int(30 * scale)
    
    # 성공 범례
    draw.ellipse([int(20 * scale), legend_y, int(20 * scale) + int(12 * scale), legend_y + int(12 * scale)], fill='#4CAF50')
    draw.text((int(40 * scale), legend_y - int(2 * scale)), "목표 달성", fill='#333333', font=small_font)
    
    # 실패 범례
    draw.ellipse([int(120 * scale), legend_y, int(120 * scale) + int(12 * scale), legend_y + int(12 * scale)], fill='#F44336')
    draw.text((int(140 * scale), legend_y - int(2 * scale)), "목표 실패", fill='#333333', font=small_font)
    
    return img

def create_realistic_statistics_screenshot(width, height):
    """통계 화면 스크린샷 생성"""
    img = Image.new('RGB', (width, height), '#FAFAFA')
    draw = ImageDraw.Draw(img)
    
    scale = min(width, height) / 400
    title_size = int(24 * scale)
    subtitle_size = int(18 * scale)
    body_size = int(16 * scale)
    small_size = int(14 * scale)
    
    try:
        title_font = ImageFont.truetype("/System/Library/Fonts/SF-Pro-Display-Bold.otf", title_size)
        subtitle_font = ImageFont.truetype("/System/Library/Fonts/SF-Pro-Display-Medium.otf", subtitle_size)
        body_font = ImageFont.truetype("/System/Library/Fonts/SF-Pro-Text-Regular.otf", body_size)
        small_font = ImageFont.truetype("/System/Library/Fonts/SF-Pro-Text-Regular.otf", small_size)
    except:
        try:
            title_font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", title_size)
            subtitle_font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", subtitle_size)
            body_font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", body_size)
            small_font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", small_size)
        except:
            title_font = subtitle_font = body_font = small_font = ImageFont.load_default()
    
    status_height = int(50 * scale)
    appbar_height = int(56 * scale)
    
    # AppBar
    draw.rectangle([0, status_height, width, status_height + appbar_height], fill='#1976D2')
    draw.text((int(20 * scale), status_height + int(16 * scale)), "통계", fill='white', font=title_font)
    
    content_start = status_height + appbar_height + int(20 * scale)
    margin = int(20 * scale)
    
    # 목표별 성공/실패 통계 섹션
    y_pos = content_start
    draw.text((margin, y_pos), "목표별 성공/실패 통계", fill='#333333', font=subtitle_font)
    
    # 목표 통계 리스트
    goals_stats = [
        {"name": "운동하기", "rate": 85.7, "success": 12, "fail": 2, "color": "#4CAF50"},
        {"name": "독서 30분", "rate": 71.4, "success": 10, "fail": 4, "color": "#2196F3"},
        {"name": "물 2L 마시기", "rate": 64.3, "success": 9, "fail": 5, "color": "#FF9800"}
    ]
    
    item_height = int(60 * scale)
    y_pos += int(40 * scale)
    
    for goal in goals_stats:
        # 목표 아이템 배경
        draw.rounded_rectangle([margin, y_pos, width - margin, y_pos + item_height],
                              radius=int(8 * scale), fill='white', outline='#E0E0E0', width=1)
        
        # 컬러 인디케이터
        indicator_size = int(30 * scale)
        draw.ellipse([margin + int(15 * scale), y_pos + int(15 * scale), 
                     margin + int(15 * scale) + indicator_size, y_pos + int(15 * scale) + indicator_size], 
                    fill=goal["color"])
        
        # 목표 이름
        text_x = margin + int(60 * scale)
        draw.text((text_x, y_pos + int(8 * scale)), goal["name"], fill='#333333', font=body_font)
        
        # 성공률
        draw.text((text_x, y_pos + int(30 * scale)), f"성공률: {goal['rate']}%", fill='#1976D2', font=small_font)
        
        # 성공/실패 횟수
        stats_x = width - int(150 * scale)
        draw.text((stats_x, y_pos + int(8 * scale)), f"성공: {goal['success']}", fill='#4CAF50', font=small_font)
        draw.text((stats_x, y_pos + int(30 * scale)), f"실패: {goal['fail']}", fill='#F44336', font=small_font)
        
        y_pos += item_height + int(12 * scale)
    
    # 일자별 전체 성공률 차트
    y_pos += int(30 * scale)
    draw.text((margin, y_pos), "일자별 전체 성공률(최근 2주)", fill='#333333', font=subtitle_font)
    
    # 차트 영역
    chart_y = y_pos + int(40 * scale)
    chart_height = int(120 * scale)
    chart_width = width - 2 * margin
    
    # 차트 배경
    draw.rounded_rectangle([margin, chart_y, width - margin, chart_y + chart_height],
                          radius=int(8 * scale), fill='white', outline='#E0E0E0', width=1)
    
    # 샘플 데이터 (14일간의 성공률)
    daily_rates = [20, 40, 80, 60, 100, 70, 90, 85, 30, 75, 95, 50, 80, 100]
    days = list(range(1, 15))  # 1일부터 14일까지
    
    bar_width = chart_width // len(daily_rates)
    max_height = chart_height - int(30 * scale)
    
    for i, rate in enumerate(daily_rates):
        bar_height = int((rate / 100) * max_height)
        x = margin + i * bar_width + int(5 * scale)
        bar_y = chart_y + chart_height - int(20 * scale) - bar_height
        
        # 막대 그래프
        draw.rectangle([x, bar_y, x + bar_width - int(10 * scale), chart_y + chart_height - int(20 * scale)], 
                      fill='#2196F3')
        
        # 날짜 라벨
        draw.text((x + int(5 * scale), chart_y + chart_height - int(15 * scale)), 
                 str(days[i]), fill='#666666', font=small_font)
    
    # Y축 라벨 (성공률)
    for i in range(0, 101, 25):
        label_y = chart_y + chart_height - int(20 * scale) - int((i / 100) * max_height)
        draw.text((margin - int(30 * scale), label_y - int(5 * scale)), f"{i}%", fill='#666666', font=small_font)
    
    return img

def main():
    """메인 함수 - 모든 스크린샷 생성"""
    
    # 출력 디렉토리 확인
    output_dir = "/Users/chajunseong/Documents/02.AOR/github/beumz/beumz_app/store_assets"
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
    
    # 스마트폰용 스크린샷 생성 (1080x1920)
    print("스마트폰용 스크린샷 생성 중...")
    
    # 홈 화면
    home_img = create_realistic_home_screenshot(1080, 1920)
    home_img.save(os.path.join(output_dir, "screenshot_phone_home.png"), "PNG", quality=95)
    print("✓ 홈 화면 스크린샷 완료")
    
    # 캘린더 화면
    calendar_img = create_realistic_calendar_screenshot(1080, 1920)
    calendar_img.save(os.path.join(output_dir, "screenshot_phone_calendar.png"), "PNG", quality=95)
    print("✓ 캘린더 화면 스크린샷 완료")
    
    # 통계 화면
    stats_img = create_realistic_statistics_screenshot(1080, 1920)
    stats_img.save(os.path.join(output_dir, "screenshot_phone_stats.png"), "PNG", quality=95)
    print("✓ 통계 화면 스크린샷 완료")
    
    # 태블릿용 스크린샷 생성 (1536x2048)
    print("\n태블릿용 스크린샷 생성 중...")
    
    # 홈 화면
    home_tablet_img = create_realistic_home_screenshot(1536, 2048)
    home_tablet_img.save(os.path.join(output_dir, "screenshot_tablet_home.png"), "PNG", quality=95)
    print("✓ 태블릿 홈 화면 스크린샷 완료")
    
    # 캘린더 화면
    calendar_tablet_img = create_realistic_calendar_screenshot(1536, 2048)
    calendar_tablet_img.save(os.path.join(output_dir, "screenshot_tablet_calendar.png"), "PNG", quality=95)
    print("✓ 태블릿 캘린더 화면 스크린샷 완료")
    
    # 통계 화면
    stats_tablet_img = create_realistic_statistics_screenshot(1536, 2048)
    stats_tablet_img.save(os.path.join(output_dir, "screenshot_tablet_stats.png"), "PNG", quality=95)
    print("✓ 태블릿 통계 화면 스크린샷 완료")
    
    print(f"\n모든 스크린샷이 생성되었습니다!")
    print(f"저장 위치: {output_dir}")
    
    # 생성된 파일 목록 출력
    print("\n생성된 파일:")
    files = [
        "screenshot_phone_home.png",
        "screenshot_phone_calendar.png", 
        "screenshot_phone_stats.png",
        "screenshot_tablet_home.png",
        "screenshot_tablet_calendar.png",
        "screenshot_tablet_stats.png"
    ]
    
    for file in files:
        file_path = os.path.join(output_dir, file)
        if os.path.exists(file_path):
            file_size = os.path.getsize(file_path) / 1024  # KB
            print(f"  ✓ {file} ({file_size:.1f} KB)")
        else:
            print(f"  ✗ {file} (생성 실패)")

if __name__ == "__main__":
    main()

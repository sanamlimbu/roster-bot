package main

import (
	"fmt"
	"log"
	"os"
	"strconv"
	"time"

	tgbotapi "github.com/go-telegram-bot-api/telegram-bot-api/v5"
)

func main() {
	botApiToken := os.Getenv("BOT_API_TOKEN")
	if botApiToken == "" {
		log.Panic("missing env: BOT_API_TOKEN")
	}

	myChatIDStr := os.Getenv("MY_CHAT_ID")
	if myChatIDStr == "" {
		log.Panic("missing env: MY_CHAT_ID")
	}

	myChatID, err := strconv.ParseInt(myChatIDStr, 10, 64)
	if err != nil {
		log.Panic("invalid env: MY_CHAT_ID, must be integer value")
	}

	bot, err := tgbotapi.NewBotAPI(botApiToken)
	if err != nil {
		log.Panic(err)
	}

	roster, err := getRoster()
	if err != nil {
		log.Fatalln(err)
	}

	err = sendRoster(bot, myChatID, roster)
	if err != nil {
		log.Fatalln(err)
	}
}

func sendRoster(bot *tgbotapi.BotAPI, chatID int64, roster string) error {
	msg := tgbotapi.NewMessage(chatID, roster)

	_, err := bot.Send(msg)

	return err
}

func getRoster() (string, error) {
	perth, err := time.LoadLocation("Australia/Perth")
	if err != nil {
		return "", err
	}

	firstDayOfCycle := time.Date(2024, 1, 1, 0, 0, 0, 0, perth)

	today := time.Now().In(perth)

	weekDay := today.Weekday().String()

	week := getWeekOfCycle(today, firstDayOfCycle)

	if week == firstWeek {
		roster, ok := WeekOneRoster[weekDay]
		if !ok {
			return "", fmt.Errorf("roster not found for first week on %s", weekDay)
		}

		return roster, nil
	}

	roster, ok := WeekTwoRoster[weekDay]
	if !ok {
		return "", fmt.Errorf("roster not found for second week on %s", weekDay)
	}

	return roster, nil
}

type week string

const (
	firstWeek  week = "first"
	secondWeek week = "second"
)

func getWeekOfCycle(t, firstDayOfCycle time.Time) week {
	daysDiff := int(t.Sub(firstDayOfCycle).Hours() / 24)

	totalCompleteWeeks := (daysDiff / 7)

	if (totalCompleteWeeks % 2) == 0 {
		return firstWeek
	}

	return secondWeek
}